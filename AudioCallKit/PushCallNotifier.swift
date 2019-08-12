/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import PushKit
import VoxImplant

protocol PushCallNotifierDelegate: AnyObject {
    func handlePushIncomingCall(_ callDescription: [AnyHashable: Any], _ completion: @escaping (Result<(), Error>)->Void)
}

var pushNotificationCompletion: (()->Void)?

// Create the PushCallNotifier instance on application launch
// This is obligatory to receive incoming calls via VoIP push from not launched application state
class PushCallNotifier: NSObject, PKPushRegistryDelegate {
    fileprivate let voipRegistry: PKPushRegistry = PKPushRegistry(queue: .main)
    
    fileprivate var client: VIClient
    fileprivate var authService: AuthService
    
    init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        super.init()
        voipRegistry.delegate = self
        
        // check if pushToken is already available
        // if not, request it from PushKit (see pushRegistry(_:didUpdate:for:))
        if let token = voipRegistry.pushToken(for: .voIP) {
            self.authService.pushToken = token
        } else {
            voipRegistry.desiredPushTypes = [.voIP]
        }
    }
    
    // MARK: PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let tokenAsString = pushCredentials.token.map {
            String(format: "%02hhx", $0)
        }.joined()
        Log.i("New push credentials: \(tokenAsString) for \(type)")
        self.authService.pushToken = pushCredentials.token
    }
    
    @available(iOS 11.0, *)
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        Log.i("\(type) Push Received: \(payload)")
        
        pushNotificationCompletion = completion
        handlePushNotification(payload.dictionaryPayload)
    }
    
    @available(iOS, introduced: 8.0, obsoleted: 11.0)
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        Log.i("\(type) Push Received: \(payload)")
        
        handlePushNotification(payload.dictionaryPayload)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        self.authService.pushToken = nil
    }
    
    // MARK: PushCallNotifierDelegate
    func handlePushNotification(_ payload: [AnyHashable : Any]) {
        // To check that the push notification is sent from the Voximplant Cloud
        // guard payload["voximplant"] != nil else { return }
        
        if let user = authService.lastLoggedInUser {
            authService.loginWithAccessToken(user: user.fullUsername)
            { [weak client] (result: Result<String, Error>) in
                if case let .failure(error) = result {
                    Log.e(error.localizedDescription)
                    pushNotificationCompletion?()
                } else {
                    client?.handlePushNotification(payload)
                }
            }
        } else {
            pushNotificationCompletion?()
        }
    }
}
