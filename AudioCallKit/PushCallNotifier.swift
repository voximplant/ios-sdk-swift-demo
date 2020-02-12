/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import PushKit
import VoxImplantSDK

protocol PushCallNotifierDelegate: AnyObject {
    func didReceiveIncomingCall(_ uuid: UUID, from fullUsername: String, withDisplayName userDisplayName: String, withPushCompletion pushProcessingCompletion: (()->Void)?)
}

// Create the PushCallNotifier instance on application launch
// This is obligatory to receive incoming calls via VoIP push from not launched application state
class PushCallNotifier: NSObject, PKPushRegistryDelegate {
    fileprivate let voipRegistry: PKPushRegistry = PKPushRegistry(queue: .main)
    
    fileprivate var client: VIClient
    fileprivate var authService: AuthService
    
    weak var delegate: PushCallNotifierDelegate?

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
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion pushProcessingCompletion: @escaping () -> Void) {
        Log.i("\(type) Push Received: \(payload)")
        
        handlePushNotification(payload.dictionaryPayload, withPushCompletion: pushProcessingCompletion)
    }
    
    @available(iOS, introduced: 8.0, deprecated: 11.0)
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        Log.i("\(type) Push Received: \(payload)")
        
        handlePushNotification(payload.dictionaryPayload, withPushCompletion: nil)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        self.authService.pushToken = nil
    }
    
    // MARK: PushCallNotifierDelegate
    func handlePushNotification(_ pushPayload: [AnyHashable : Any], withPushCompletion pushProcessingCompletion: (()->Void)?) {
        let callUUID: UUID = client.handlePushNotification(pushPayload)!
        let userDisplayName: String = pushPayload.displayName
        let fullUsername: String = pushPayload.fullUsername
        
        delegate?.didReceiveIncomingCall(callUUID, from: fullUsername, withDisplayName: userDisplayName, withPushCompletion: pushProcessingCompletion)
    }
}


fileprivate extension Dictionary where Key == AnyHashable {
    var isVoximplantPushPayload: Bool {
        return self["voximplant"] != nil
    }
    
    var displayName: String {
        let voximplantContent = self["voximplant"] as! [String:Any]
        return voximplantContent["display_name"] as! String
    }
    
    var fullUsername: String {
        return self.displayName
    }
}
