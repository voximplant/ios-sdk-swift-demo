/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import VoxImplantSDK

typealias ConnectCompletion = (Error?) -> Void
typealias DisconnectCompletion = () -> Void
typealias LoginResult = Result<String, Error>
typealias LoginCompletion = (LoginResult) -> Void

final class AuthService: NSObject, VIClientSessionDelegate, PushTokenHolder {
    fileprivate var client: VIClient
    fileprivate var connectCompletion: ConnectCompletion?
    fileprivate var disconnectCompletion: DisconnectCompletion?
    var possibleToLogin: Bool { Tokens.areExist && !Tokens.areExpired }
    var pushToken: Data? {
        willSet {
            if pushToken != nil && newValue == nil {
                client.unregisterPushNotificationsToken(pushToken, imToken: nil)
            }
        }
    }
    @UserDefault("lastFullUsername")
    var loggedInUser: String?
    var loggedInUserDisplayName: String?
    var state: VIClientState {
        client.clientState
    }
    
    init(_ client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
    }
        
    func login(user: String, password: String, _ completion: @escaping LoginCompletion) {
        connect() { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.client.login(withUser: user, password: password,
                success: { (displayUserName: String, tokens: VIAuthParams) in
                    Tokens.update(with: tokens)
                    self?.loggedInUser = user
                    self?.loggedInUserDisplayName = displayUserName
                    if let pushToken = self?.pushToken {
                        self?.client.registerPushNotificationsToken(pushToken, imToken: nil)
                    }
                    completion(.success(displayUserName))
                },
                failure: { (error: Error) in
                    completion(.failure(error))
                }
            )
        }
    }
    
    func loginWithAccessToken(_ completion: @escaping LoginCompletion) {
        guard let user = self.loggedInUser else {
            let error = AuthError.loginDataNotFound
            completion(.failure(error))
            return
        }
        
        if client.clientState == .loggedIn,
            let loggedInUserDisplayName = self.loggedInUserDisplayName,
            !Tokens.areExpired
        {
            completion(.success(loggedInUserDisplayName))
            return
        }
    
        connect() { [weak self] error in
            if let error = error  {
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
                            Tokens.update(with: tokens)
                            self?.loggedInUser = user
                            self?.loggedInUserDisplayName = displayUserName
                            if let pushToken = self?.pushToken {
                                self?.client.registerPushNotificationsToken(pushToken, imToken: nil)
                            }
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
    
    fileprivate func updateAccessTokenIfNeeded(for user: String,
                                               _ completion: @escaping (Result<Token, Error>)->Void) {
        guard let accessToken = Tokens.access,
            let refreshToken = Tokens.refresh else {
                completion(.failure(AuthError.loginDataNotFound))
                return
        }
        
        if accessToken.isExpired {
            client.refreshToken(withUser: user, token: refreshToken.token)
            { (authParams: VIAuthParams?, error: Error?) in
                guard let tokens = authParams
                else {
                    completion(.failure(error!))
                    return
                }
                Tokens.update(with: tokens)
                completion(.success(Tokens.access!))
            }
        } else {
            completion(.success(accessToken))
        }
    }
    
    fileprivate func connect(_ completion: @escaping ConnectCompletion) {
        if client.clientState == .disconnected ||
           client.clientState == .connecting
        {
            connectCompletion = completion
            client.connect()
        } else {
            completion(nil)
        }
    }
    
    fileprivate func disconnect(_ completion: @escaping DisconnectCompletion) {
        if client.clientState == .disconnected {
            completion()
        } else {
            disconnectCompletion = completion
            client.disconnect()
        }
    }
    
    func logout(_ completion: @escaping () -> Void) {
        client.unregisterPushNotificationsToken(pushToken, imToken: nil)
        Tokens.clear()
        disconnect(completion)
    }
    
    // MARK: - VIClientSessionDelegate -
    func clientSessionDidConnect(_ client: VIClient) {
        connectCompletion?(nil)
        connectCompletion = nil
    }
    
    func client(_ client: VIClient, sessionDidFailConnectWithError error: Error) {
        connectCompletion?(error)
        connectCompletion = nil
    }
    
    func clientSessionDidDisconnect(_ client: VIClient) {
        disconnectCompletion?()
        disconnectCompletion = nil
    }
}
