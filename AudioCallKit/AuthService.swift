/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplant

extension UserDefaults {
    var lastFullUsername: String {
        return UIApplication.userDefaultsDomain + "." + "lastFullUsername"
    }
}

class AuthService: NSObject, VIClientSessionDelegate {
    fileprivate var userDefaults = UserDefaults.standard
    fileprivate var client: VIClient
    fileprivate var tokensManager = TokenManager()
    fileprivate var connectCompletion: ((Result<(), Error>)->Void)?
    fileprivate var disconnectCompletion: (() -> Void)?
    var pushToken: Data? {
        willSet {
            if pushToken != nil && newValue == nil {
                client.unregisterPushNotificationsToken(pushToken, imToken: nil)
            }
        }
    }
    
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
    var state: VIClientState {
        return client.clientState
    }
        
    func login(user: String, password: String, _ completion: @escaping (Result<String, Error>)->Void) {
        connect()
        { [weak self]
            (result: Result<(), Error>) in
            if case let .failure(error) = result  {
                completion(.failure(error))
                return
            }
            
            self?.client.login(withUser: user, password: password,
            success: { (displayUserName: String, tokens: [AnyHashable : Any]) in
                if let refreshToken = tokens.refreshToken,
                   let accessToken = tokens.accessToken
                {
                    self?.tokensManager.keys = (accessToken, refreshToken)
                    self?.loggedInUser = user
                    self?.loggedInUserDisplayName = displayUserName
                }
                if let pushToken = self?.pushToken {
                    self?.client.registerPushNotificationsToken(pushToken, imToken: nil)
                }
                completion(.success(displayUserName))
            },
            failure: { (error: Error) in
                completion(.failure(error))
            })
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
                        success: { (displayUserName: String, tokens: [AnyHashable : Any]) in
                            if let accessToken = tokens.accessToken,
                               let refreshToken = tokens.refreshToken
                            {
                                self?.tokensManager.keys = (accessToken,refreshToken)
                                self?.loggedInUser = user
                                self?.loggedInUserDisplayName = displayUserName
                            }
                            if let pushToken = self?.pushToken {
                                self?.client.registerPushNotificationsToken(pushToken, imToken: nil)
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
    
    fileprivate func updateAccessTokenIfNeeded(for user: String, _ completion: @escaping (Result<Token, Error>)->Void) {
        guard let tokens = tokensManager.keys else {
            completion(.failure(VoxDemoError.errorRequiredPassword()))
            return
        }
        
        if tokens.access.isExpired {
            client.refreshToken(withUser: user, token: tokens.refresh.token)
            { [weak self] (authParams: [AnyHashable: Any]?, error: Error?) in
                guard let tokens = authParams,
                      let refreshToken = tokens.refreshToken,
                      let accessToken = tokens.accessToken
                else {
                        completion(.failure(error!))
                        return
                }
                self?.tokensManager.keys = (accessToken, refreshToken)
                completion(.success(accessToken))
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
    
    fileprivate func disconnect(_ completion: @escaping ()->Void) {
        if client.clientState == .disconnected {
            completion()
        } else {
            disconnectCompletion = completion
            client.disconnect()
        }
    }
    
    func logout(_ completion: @escaping ()->Void) {
        client.unregisterPushNotificationsToken(pushToken, imToken: nil)
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


fileprivate extension Dictionary where Key == AnyHashable {
    var refreshExpire: Date? {
        get {
            if let refreshExpire = self["refreshExpire"] as? Int {
                return Date(timeIntervalSinceNow: TimeInterval(refreshExpire))
            } else {
                return nil
            }
        }
    }
    
    var refreshTokenContent: String? {
        get {
            return self["refreshToken"] as? String
        }
    }
    
    var accessExpire: Date? {
        get {
            if let accessExpire = self["accessExpire"] as? Int {
                return Date(timeIntervalSinceNow: TimeInterval(accessExpire))
            } else {
                return nil
            }
        }
    }
    
    var accessTokenContent: String? {
        get {
            return self["accessToken"] as? String
        }
    }
    
    var accessToken: Token? {
        get {
            if let accessExpire = self.accessExpire,
               let accessTokenContent = self.accessTokenContent
            {
                return Token(token: accessTokenContent, expireDate: accessExpire)
            } else {
                return nil
            }
        }
    }
    
    var refreshToken: Token? {
        get {
            if let refreshExpire = self.refreshExpire,
               let refreshTokenContent = self.refreshTokenContent
            {
                return Token(token: refreshTokenContent, expireDate: refreshExpire)
            } else {
                return nil
            }
        }
    }
}
