/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplant

extension UserDefaults {
    var lastFullUsername: String {
        return UIApplication.userDefaultsDomain + "." + "lastFullUsername"
    }
    
    var lastDisplayName: String {
        return UIApplication.userDefaultsDomain + "." + "lastDisplayName"
    }
}

typealias User = (fullUsername: String, displayName: String)

class AuthService: NSObject, VIClientSessionDelegate {
    fileprivate var userDefaults = UserDefaults.standard
    fileprivate var client: VIClient
    fileprivate var tokensManager = TokenManager()
    fileprivate var connectCompletion: ((Result<(), Error>)->Void)?
    fileprivate var disconnectCompletion: (() -> Void)?
    
    init(_ client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
    }
    
    var lastLoggedInUser: User? {
        get {
            guard let fullUsername = userDefaults.string(forKey: userDefaults.lastFullUsername),
                  let displayName = userDefaults.string(forKey: userDefaults.lastDisplayName)
            else { return nil }
            return User(fullUsername: fullUsername, displayName: displayName)
        }
        set {
            userDefaults.set(newValue?.fullUsername, forKey: userDefaults.lastFullUsername)
            userDefaults.set(newValue?.displayName, forKey: userDefaults.lastDisplayName)
        }
    }
    
    func login(user: String, password: String, _ completion: @escaping (Result<String, Error>)->Void) {
        disconnect {
            [weak self] in
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
                        let accessToken = Token(token: accessToken, expireDate: Date(timeIntervalSinceNow: TimeInterval(accessExpire)))
                        let refreshToken = Token(token: refreshToken, expireDate: Date(timeIntervalSinceNow: TimeInterval(refreshExpire)))
                        self?.tokensManager.keys = (accessToken, refreshToken)
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
        
        if client.clientState == .loggedIn {
            completion(.success(lastLoggedInUser?.displayName ?? " "))
            return
        }
        
        disconnect {
            [weak self] in
            self?.connect {
                
                [weak self]
                (result: Result<(), Error>) in
                if case let .failure(error) = result  {
                    completion(.failure(error))
                    return
                }
                
                self?.updateAccessTokenIfNeeded(for: user) {
                    [weak self]
                    (result: Result<Token, Error>) in
                    
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
                                    let accessToken = Token(token: accessToken, expireDate: Date(timeIntervalSinceNow: TimeInterval(accessExpire)))
                                    let refreshToken = Token(token: refreshToken, expireDate: Date(timeIntervalSinceNow: TimeInterval(refreshExpire)))
                                    self?.tokensManager.keys = (accessToken,refreshToken)
                                    self?.lastLoggedInUser = User(fullUsername: user, displayName: displayUserName)
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
    
    fileprivate func updateAccessTokenIfNeeded(for user: String, _ completion: @escaping (Result<Token, Error>)->Void) {
        guard let tokens = tokensManager.keys else {
            completion(.failure(VoxDemoError.errorRequiredPassword()))
            return
        }
        
        if tokens.access.isExpired {
            client.refreshToken(withUser: user, token: tokens.refresh.token)
            { [weak self] (authParams: [AnyHashable: Any]?, error: Error?) in
                guard let tokens = authParams,
                    let refreshExpire = tokens["refreshExpire"] as? Int,
                    let refreshToken = tokens["refreshToken"] as? String,
                    let accessExpire = tokens["accessExpire"] as? Int,
                    let accessToken = tokens["accessToken"] as? String else {
                        completion(.failure(error!))
                        return
                }
                let vaildAccessToken = Token(token: accessToken, expireDate: Date(timeIntervalSinceNow: TimeInterval(accessExpire)))
                let validRefreshToken = Token(token: refreshToken, expireDate: Date(timeIntervalSinceNow: TimeInterval(refreshExpire)))
                self?.tokensManager.keys = (vaildAccessToken, validRefreshToken)
                completion(.success(vaildAccessToken))
            }
        } else {
            completion(.success(tokens.access))
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
    
    func possibleToLogin(for user: String) -> Date? {
        return tokensManager.keys?.refresh.expireDate
    }
    
    func disconnect(_ completion: @escaping ()->Void) {
        if client.clientState == .disconnected {
            completion()
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
        disconnectCompletion?()
        disconnectCompletion = nil
    }
}
