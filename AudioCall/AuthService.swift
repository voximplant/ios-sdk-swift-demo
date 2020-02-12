/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplantSDK

extension UserDefaults {
    var lastFullUsername: String {
        return UIApplication.userDefaultsDomain + "." + "lastFullUsername"
    }
    
    var lastDisplayName: String {
        return UIApplication.userDefaultsDomain + "." + "lastDisplayName"
    }
}

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
    
    var loggedInUser: String? {
        get {
            return userDefaults.string(forKey: userDefaults.lastFullUsername)
        }
        set {
            userDefaults.set(newValue, forKey: userDefaults.lastFullUsername)
        }
    }
    
    var loggedInUserDisplayName: String?
    
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
                    success: { (displayUserName: String, tokens: VIAuthParams) in
                        let accessToken = Token(token: tokens.accessToken, expireDate: Date(timeIntervalSinceNow: tokens.accessExpire))
                        let refreshToken = Token(token: tokens.refreshToken, expireDate: Date(timeIntervalSinceNow: tokens.refreshExpire))
                        self?.tokensManager.keys = (accessToken, refreshToken)
                        self?.loggedInUser = user
                        self?.loggedInUserDisplayName = displayUserName
                        completion(.success(displayUserName))
                    },
                    failure: { (error: Error) in
                        completion(.failure(error))
                    }
                )
            }
        }
    }
    
    func loginWithAccessToken(_ completion: @escaping (Result<String, Error>)->Void) {
        
        guard let user = self.loggedInUser else {
            let error = VoxDemoError.errorRequiredPassword()
            completion(.failure(error))
            return
        }
        
        if client.clientState == .loggedIn,
           let loggedInUserDisplayName = self.loggedInUserDisplayName,
           let keys = tokensManager.keys,
           !keys.refresh.isExpired
        {
            completion(.success(loggedInUserDisplayName))
            return
        }
        
            connect() {
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
                            success: { (displayUserName: String, tokens: VIAuthParams) in
                                let accessToken = Token(token: tokens.accessToken, expireDate: Date(timeIntervalSinceNow: tokens.accessExpire))
                                let refreshToken = Token(token: tokens.refreshToken, expireDate: Date(timeIntervalSinceNow: tokens.refreshExpire))
                                self?.tokensManager.keys = (accessToken,refreshToken)
                                self?.loggedInUser = user
                                self?.loggedInUserDisplayName = displayUserName
                                completion(.success(displayUserName))
                            },
                            failure: { (error: Error) in
                                completion(.failure(error))
                            }
                        )
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
            { [weak self] (authParams: VIAuthParams?, error: Error?) in
                guard let tokens = authParams
                else {
                        completion(.failure(error!))
                        return
                }
                let vaildAccessToken = Token(token: tokens.accessToken, expireDate: Date(timeIntervalSinceNow: tokens.accessExpire))
                let validRefreshToken = Token(token: tokens.refreshToken, expireDate: Date(timeIntervalSinceNow: tokens.refreshExpire))
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
    
    func possibleToLogin() -> Date? {
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
    
    func logout(_ completion: @escaping ()->Void) {
        tokensManager.keys = nil
        disconnect(completion)
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
