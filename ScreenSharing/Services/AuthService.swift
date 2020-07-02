/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

// This class is common for ScreenSharing app and ScreenSharingUploadAppex
final class AuthService: NSObject, VIClientSessionDelegate {
    private typealias ConnectCompletion = (Error?) -> Void
    private typealias DisconnectCompletion = () -> Void
    typealias LoginCompletion = (Error?) -> Void
    typealias LogoutCompletion = () -> Void
    
    private let client: VIClient
    private var connectCompletion: ConnectCompletion?
    private var disconnectCompletion: DisconnectCompletion?
    var possibleToLogin: Bool { Tokens.areExist && !Tokens.areExpired }
    
    init(_ client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
    }
    
    @UserDefault("lastFullUsername")
    var loggedInUser: String?
    var loggedInUserDisplayName: String?
    var isLoggedIn: Bool { state == .loggedIn }
    private var state: VIClientState { client.clientState }
        
    func login(user: String, password: String, _ completion: @escaping LoginCompletion) {
        connect() { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            
            self?.client.login(withUser: user, password: password,
                success: { (displayUserName: String, tokens: VIAuthParams) in
                    Tokens.update(with: tokens)
                    self?.loggedInUser = user
                    self?.loggedInUserDisplayName = displayUserName
                    completion(nil)
                },
                failure: { (error: Error) in
                    completion(error)
                }
            )
        }
    }
    
    func loginWithAccessToken(_ completion: @escaping LoginCompletion) {
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
            
            self?.updateAccessTokenIfNeeded(for: user) { [weak self] result in
                switch result {
                    
                case let .failure(error):
                    completion(error)
                    return
                    
                case let .success(accessKey):
                    self?.client.login(withUser: user, token: accessKey.token,
                        success: { (displayUserName: String, tokens: VIAuthParams) in
                            Tokens.update(with: tokens)
                            self?.loggedInUser = user
                            self?.loggedInUserDisplayName = displayUserName
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
    
    func logout(_ completion: @escaping LogoutCompletion) {
        Tokens.clear()
        self.loggedInUser = nil
        self.loggedInUserDisplayName = nil
        self.disconnect(completion)
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
            completion()
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
        disconnectCompletion?()
        disconnectCompletion = nil
    }
}
