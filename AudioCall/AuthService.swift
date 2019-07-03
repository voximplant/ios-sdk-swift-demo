/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplant

extension UserDefaults {
    var lastUserIDKey: String {
        return "com.voximplant.demos.swift.latestUserID"
    }
    
    var lastUserNameKey: String {
        return "com.voximplant.demos.swift.latestUserDisplayName"
    }
}

typealias User = (id: String, displayName: String)

class AuthService: NSObject, VIClientSessionDelegate {
    fileprivate var userDefaults = UserDefaults.standard
    fileprivate var client: VIClient
    fileprivate var tokensManager = TokenManager()
    fileprivate var connectCompletion: ((Result<(), Error>)->Void)?
    fileprivate var disconnectCompletion: ((Result<(), Error>) -> Void)?
    
    init(_ client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
    }
    
    var lastLoggedInUser: User? {
        get {
            guard let id = userDefaults.string(forKey: userDefaults.lastUserIDKey),
                  let displayName = userDefaults.string(forKey: userDefaults.lastUserNameKey)
            else { return nil }
            return User(id: id, displayName: displayName)
        }
        set {
            userDefaults.set(newValue?.id, forKey: userDefaults.lastUserIDKey)
            userDefaults.set(newValue?.displayName, forKey: userDefaults.lastUserNameKey)
        }
    }
    
    // only one current user is supported
    var currentUser: User? {
        if client.clientState == .loggedIn {
            return lastLoggedInUser
        } else {
            return nil
        }
    }
    
    fileprivate func connect(_ completion: @escaping (Result<(), Error>)->Void) {
        if client.clientState == .disconnected ||
           client.clientState == .connecting
        {
            connectCompletion = completion
            client.connect()
        } else {
            completion(.success(()))
        }
    }
    
    fileprivate func updateAccessTokenIfNeeded(for user: String, _ completion: @escaping (Result<AccessKey, Error>)->Void) {
        if let accessKey = tokensManager[user].access { // get access token for user
            completion(.success(accessKey))
        } else if let refreshKey = tokensManager[user].refresh { // get refresh token for user
            client.refreshToken(withUser: refreshKey.user, token: refreshKey.token)
            { [weak self]
                (authParams: [AnyHashable: Any]?, error: Error?) in
                if let error = error {
                    completion(.failure(error))
                } else if let tokens = authParams,
                    let refreshExpire = tokens["refreshExpire"] as? Int,
                    let refreshToken = tokens["refreshToken"] as? String,
                    let accessExpire = tokens["accessExpire"] as? Int,
                    let accessToken = tokens["accessToken"] as? String
                {
                    let accessKey = AccessKey(user: user, token: accessToken, expire: Date(timeIntervalSinceNow: TimeInterval(accessExpire)))
                    let refreshKey = RefreshKey(user: user, token: refreshToken, expire: Date(timeIntervalSinceNow: TimeInterval(refreshExpire)))
                    self?.tokensManager[user] = (accessKey, refreshKey)
                    completion(.success(accessKey))
                } else {
                    abort() // unreachable branch
                }
            }
            
        } else { // no refresh token, no access token
            completion(.failure(NSError(domain: "User password is needed for login", code: 5017, userInfo: nil)))
        }
    }
    
    func login(user: String, password: String, _ completion: @escaping (Result<String, Error>)->Void) {
        disconnect {
            [weak self] _ in
            self?.connect
            { [weak self]
                (result: Result<(), Error>) in
                if case let .failure(error) = result  {
                    completion(.failure(error))
                    return
                }
                
                self?.client.login(withUser: user, password: password,
                success: { (displayUserName: String, tokens: [AnyHashable : Any]) in
                    if let refreshExpire = tokens["refreshExpire"] as? Int,
                        let refreshToken = tokens["refreshToken"] as? String,
                        let accessExpire = tokens["accessExpire"] as? Int,
                        let accessToken = tokens["accessToken"] as? String
                    {
                        let refreshKey = RefreshKey(user: user, token: refreshToken, expire: Date(timeIntervalSinceNow: TimeInterval(refreshExpire)))
                        let accessKey = AccessKey(user: user, token: accessToken, expire: Date(timeIntervalSinceNow: TimeInterval(accessExpire)))
                        self?.tokensManager[user] = (accessKey, refreshKey)
                        self?.lastLoggedInUser = User(user,displayUserName)
                    }
                    completion(.success(displayUserName))
                },
                failure: { (error: Error) in
                    completion(.failure(error))
                })
            }
        }
    }
    
    func loginWithAccessToken(user: String, _ completion: @escaping (Result<String, Error>)->Void) {
        if currentUser?.id == user
        {
            completion(.success(currentUser?.displayName ?? "Name did'nt load"))
            return
        }
        
        disconnect {
            [weak self] _ in
            self?.connect {
                [weak self]
                (result: Result<(), Error>) in
                if case let .failure(error) = result  {
                    completion(.failure(error))
                    return
                }
                
                self?.updateAccessTokenIfNeeded(for: user) {
                    [weak self]
                    (result: Result<(AccessKey), Error>) in
                    
                    switch result {
                    case let .failure(error):
                        completion(.failure(error))
                        return
                        
                    case let .success(accessKey):
                        self?.client.login(withUser: user, token: accessKey.token,
                        success: { (displayUserName: String, tokens: [AnyHashable : Any]) in
                            if let refreshExpire = tokens["refreshExpire"] as? Int,
                                let refreshToken = tokens["refreshToken"] as? String,
                                let accessExpire = tokens["accessExpire"] as? Int,
                                let accessToken = tokens["accessToken"] as? String
                            {
                                let refreshKey = RefreshKey(user: user, token: refreshToken, expire: Date(timeIntervalSinceNow: TimeInterval(refreshExpire)))
                                let accessKey = AccessKey(user: user, token: accessToken, expire: Date(timeIntervalSinceNow: TimeInterval(accessExpire)))
                                self?.tokensManager[user] = (accessKey, refreshKey)
                                self?.lastLoggedInUser = User(id: user, displayName: displayUserName)
                            }
                            completion(.success(displayUserName))
                        },
                        failure: { (error: Error) in
                            completion(.failure(error))
                        })
                    }
                }
            }
        }
    }
    
    func possibleToLogin(for user: String) -> Date? {
        return tokensManager[user].refresh?.expire
    }
    
    func disconnect(_ completion: @escaping (Result<(), Error>)->Void) {
        if client.clientState == .disconnected {
            completion(.success(()))
        } else {
            disconnectCompletion = completion
            client.disconnect()
        }
    }
    
    // MARK: VIClientSessionDelegate
    
    func clientSessionDidConnect(_ client: VIClient) {
        connectCompletion?(.success(()))
        connectCompletion = nil
    }
    
    func client(_ client: VIClient, sessionDidFailConnectWithError error: Error) {
        connectCompletion?(.failure(error))
        connectCompletion = nil
    }
    
    func clientSessionDidDisconnect(_ client: VIClient) {
        disconnectCompletion?(.success(()))
        disconnectCompletion = nil
    }
}
