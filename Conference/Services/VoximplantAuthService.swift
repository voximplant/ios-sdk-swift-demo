/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplant

protocol AuthService {
    func login(with user: String, and password: String, completion: @escaping (Error?) -> Void)
    func logout(completion: @escaping () -> Void)
}

final class VoximplantAuthService: NSObject, VIClientSessionDelegate, AuthService {
    private let client: VIClient
    private var connectCompletion: ((Error?) -> Void)?
    private var disconnectCompletion: (() -> Void)?
    
    required init(client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
    }
    
    func login(with user: String, and password: String, completion: @escaping (Error?) -> Void) {
        connect { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            
            self?.client.login(
                withUser: "\(user)@conf.demovideoconf.voximplant.com",
                password: password,
                success: { _, _ in completion(nil) },
                failure: { completion($0) }
            )
        }
    }
    
    func logout(completion: @escaping () -> Void) {
        disconnect(completion)
    }
    
    private func connect(completion: @escaping (Error?) -> Void) {
        if client.clientState == .disconnected ||
           client.clientState == .connecting
        {
            connectCompletion = completion
            client.connect()
        } else {
            print("Already connected - executing completion")
            completion(nil)
        }
    }
    
    private func disconnect(_ completion: @escaping () -> Void) {
        if client.clientState == .disconnected {
            print("Already disconnected - executing completion")
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
