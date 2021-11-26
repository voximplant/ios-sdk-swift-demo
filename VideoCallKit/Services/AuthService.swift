/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class AuthService: NSObject, VIClientSessionDelegate, PushTokenHolder {
    private typealias ConnectCompletion = (Error?) -> Void
    private typealias DisconnectCompletion = (Error?) -> Void
    typealias LoginCompletion = (Error?) -> Void
    typealias LogoutCompletion = (Error?) -> Void
    
    private let client: VIClient
    private var connectCompletion: ConnectCompletion?
    private var disconnectCompletion: DisconnectCompletion?
    var possibleToLogin: Bool { Tokens.areExist && !Tokens.areExpired }
    var pushToken: Data? {
        willSet {
            guard let pushToken = pushToken, newValue == nil else { return }
            client.unregisterVoIPPushNotificationsToken(pushToken) { error in
                if let error = error {
                    print("unregister VoIP token failed with error \(error.localizedDescription)")
                }
            }
        }
    }
    @UserDefault("lastFullUsername")
    var loggedInUser: String?
    var loggedInUserDisplayName: String?
    var state: VIClientState { client.clientState }
    var isLoggedIn: Bool { state == .loggedIn || state == .reconnecting  }
    
    init(_ client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
    }
    
    func login(user: String, password: String, _ completion: @escaping LoginCompletion) {
        connect() { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            
            self?.client.login(withUser: user, password: password,
                               success: { (displayUserName: String, tokens: VIAuthParams?) in
                if let tokens = tokens {
                    Tokens.update(with: tokens)
                }
                self?.loggedInUser = user
                self?.loggedInUserDisplayName = displayUserName
                if let pushToken = self?.pushToken {
                    self?.client.registerVoIPPushNotificationsToken(pushToken) { error in
                        if let error = error {
                            print("register VoIP token failed with error \(error.localizedDescription)")
                        }
                    }
                }
                completion(nil)
            },
                               failure: { (error: Error) in
                completion(error)
            })
        }
    }
    
    func loginWithAccessToken(registerPushToken: Bool = true, completion: @escaping LoginCompletion) {
        guard let user = self.loggedInUser else {
            let error = AuthError.loginDataNotFound
            completion(error)
            return
        }
        
        if client.clientState == .loggedIn,
           loggedInUserDisplayName != nil,
           !Tokens.areExpired
        {
            completion(nil)
            return
        }
        
        connect() { [weak self] error in
            if let error = error  {
                completion(error)
                return
            }
            
            self?.updateAccessTokenIfNeeded(for: user) {
                [weak self]
                (result: Result<Token, Error>) in
                
                switch result {
                case let .failure(error):
                    completion(error)
                    return
                    
                case let .success(accessKey):
                    self?.client.login(withUser: user, token: accessKey.token,
                                       success: { (displayUserName: String, tokens: VIAuthParams?) in
                        if let tokens = tokens {
                            Tokens.update(with: tokens)
                        }
                        self?.loggedInUser = user
                        self?.loggedInUserDisplayName = displayUserName
                        if let pushToken = self?.pushToken, registerPushToken  {
                            self?.client.registerVoIPPushNotificationsToken(pushToken) { error in
                                if let error = error {
                                    print("register VoIP token failed with error \(error.localizedDescription)")
                                }
                            }
                        }
                        completion(nil)
                    },
                                       failure: { (error: Error) in
                        completion(error)
                    }
                    )
                }
            }
        }
    }
    
    func unregisterPushToken(token: Data,  completion: @escaping (Error?) -> Void) {
        self.client.unregisterVoIPPushNotificationsToken(token) { error in
            if let error = error {
                print("unregister VoIP token failed with error \(error.localizedDescription)")
                completion(error)
            } else {
                self.disconnect(completion)
                self.loggedInUserDisplayName = nil
                Tokens.clear()
            }
        }
    }
    
    func logout(_ completion: @escaping LogoutCompletion) {
        guard let pushToken = self.pushToken else {
            self.disconnect(completion)
            self.loggedInUserDisplayName = nil
            Tokens.clear()
            return
        }
        if client.clientState != .loggedIn {
            loginWithAccessToken(registerPushToken: false, completion: { error in
                if let error = error {
                    print("login with acces token failed with error \(error.localizedDescription)")
                    completion(error)
                } else {
                    self.unregisterPushToken(token: pushToken, completion: completion)
                }
            })
        } else {
            self.unregisterPushToken(token: pushToken, completion: completion)
        }
    }
    
    private func updateAccessTokenIfNeeded(
        for user: String,
        _ completion: @escaping (Result<Token, Error>)->Void
    ) {
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
    
    private func connect(_ completion: @escaping ConnectCompletion) {
        if client.clientState == .disconnected ||
           client.clientState == .connecting
        {
            connectCompletion = completion
            client.connect()
        } else {
            completion(nil)
        }
    }
    
    private func disconnect(_ completion: @escaping DisconnectCompletion) {
        if client.clientState == .disconnected {
            completion(nil)
        } else {
            disconnectCompletion = completion
            client.disconnect()
        }
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
        disconnectCompletion?(nil)
        disconnectCompletion = nil
    }
}
