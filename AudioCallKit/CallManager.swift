/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CallKit

class CallManager: NSObject, CXProviderDelegate, VICallDelegate, VIClientCallManagerDelegate {
    fileprivate var client: VIClient
    fileprivate var authService: AuthService
    fileprivate var pushCallNotifier: PushCallNotifier
    
    // Voximplant SDK supports multiple calls at the same time, however
    // this demo app demonstrates only one managed call at the moment,
    // so it rejects new incoming call, if there is already a call.
    fileprivate(set) var managedCall: (VICall, uuid: UUID, isOutgoing: Bool, hasConnected: Bool)? {
        willSet {
            managedCall?.0.remove(self)
        }
        didSet {
            managedCall?.0.add(self)
        }
    }

    func hasManagedCall() -> Bool {
        return managedCall != nil
    }
    
    fileprivate let callProvider: CXProvider = {
        let providerConfiguration = CXProviderConfiguration(localizedName: "AudioCallKit")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.ringtoneSound = "ringtone.aiff"
        if let logo = UIImage(named: "CallKitLogo") {
            providerConfiguration.iconTemplateImageData = logo.pngData()
        }
        
        return CXProvider(configuration: providerConfiguration)
    }()
    
    init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        self.pushCallNotifier = PushCallNotifier(client, authService)
        
        super.init()
        
        self.client.callManagerDelegate = self
        self.callProvider.setDelegate(self, queue: nil)
    }
    
    deinit {
        // The CXProvider documentation said: "The provider must be invalidated before it is deallocated."
        callProvider.invalidate()
    }
    
    fileprivate func startOutgoingCall(_ contact: String, _ completion: @escaping (Result<VICall, Error>) -> Void) {
        if let lastLoggedInUser = authService.lastLoggedInUser {
            authService.loginWithAccessToken(user: lastLoggedInUser.fullUsername)
            { [weak self] (result: Result<String, Error>) in
                switch result {
                case let .failure(error):
                    Log.e("Can't start outgoing call: \(error.localizedDescription)")
                    completion(.failure(error))
                case .success(_):
                    if let sself = self,
                       let client = self?.client,
                       !sself.hasManagedCall()
                    {
                        let settings = VICallSettings()
                        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
                        
                        // could be nil only if the client is not logged in:
                        if let call: VICall = client.call(contact, settings: settings) {
                            call.start()
                            completion(.success(call))
                        } else {
                            completion(.failure(VoxDemoError.errorCouldntCreateCall()))
                        }
                    } else {
                        completion(.failure(VoxDemoError.errorAlreadyHasCall()))
                    }
                }
            }
        }
    }
    
    // MARK: CXProviderDelegate
    
    // for outgoing call only
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        
        // callKitConfigureAudioSession should be called before VICall.start() method
        VIAudioManager.shared().callKitConfigureAudioSession(nil)
        
        startOutgoingCall(action.handle.value)
        { [weak self] (result: Result<VICall, Error>) in
            switch (result, self) {
            case let (.success(call), sself?):
                sself.managedCall = (call, uuid: action.callUUID, isOutgoing: true, hasConnected: false)
                action.fulfill()
            case let (.failure(error), _):
                Log.e(error.localizedDescription)
                fallthrough
            default:
                action.fail()
            }
        }
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStartAudio()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStopAudio()
    }
    
    func providerDidReset(_ provider: CXProvider) {
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // In this sample we don't need to check the client state in this method - here we are sure we are already logged in to the Voximplant Cloud.
        
        // callKitConfigureAudioSession should be called before VICall.answer(with:) method
        VIAudioManager.shared().callKitConfigureAudioSession(nil)
        
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
        managedCall?.0.answer(with: settings)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        managedCall?.0.setHold(action.isOnHold)
        { error in
            if let error = error {
                Log.e(error.localizedDescription)
                action.fail()
            } else {
                action.fulfill()
            }
        }
    }
    
    // the method is called if the user rejects an incoming call or ends a call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if let call = managedCall {
            if !call.hasConnected && !call.isOutgoing {
                call.0.reject(with: .decline, headers: nil)
            } else {
                call.0.hangup(withHeaders: nil)
            }
        }
        // If we have reported the call to CallKit, we should invoke callKitReleaseAudioSession method after hangup or reject
        VIAudioManager.shared().callKitReleaseAudioSession()
        action.fulfill(withDateEnded: Date())
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        managedCall?.0.sendDTMF(action.digits)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        managedCall?.0.sendAudio = !action.isMuted
        action.fulfill()
    }
    
    // MARK: VICallDelegate
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        if let managedCall = self.managedCall,
           managedCall.0.callId == call.callId
        {
            callProvider.reportCall(with: managedCall.uuid, endedAt: Date(), reason: .failed)
            self.managedCall = nil
        }
        
        pushNotificationCompletion?()
        pushNotificationCompletion = nil
    }
    
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        if let managedCall = self.managedCall,
           managedCall.0.callId == call.callId
        {
            let endReason: CXCallEndedReason = answeredElsewhere.boolValue ? .answeredElsewhere : .remoteEnded
            callProvider.reportCall(with: managedCall.uuid, endedAt: Date(), reason: endReason)
            
            self.managedCall = nil
        }
        
        pushNotificationCompletion?()
        pushNotificationCompletion = nil
    }
    
    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable : Any]?) {
        if let managedCall = self.managedCall {
            if managedCall.isOutgoing {
                // notify CallKit that the outgoing call is connected
                callProvider.reportOutgoingCall(with: managedCall.uuid, connectedAt: nil)
                
                // apply the configuration to the CallKit call screen
                // for incoming calls this configuration is set, when the incoming call is reported to CallKit
                let callinfo = CXCallUpdate()
                callinfo.hasVideo = false
                callinfo.supportsHolding = true
                callinfo.supportsGrouping = false
                callinfo.supportsUngrouping = false
                callinfo.supportsDTMF = true
                callinfo.localizedCallerName = call.endpoints.first?.userDisplayName
                
                callProvider.reportCall(with: managedCall.uuid, updated: callinfo)
            }
            self.managedCall?.hasConnected = true
        }
        
        pushNotificationCompletion?()
        pushNotificationCompletion = nil
    }

    // MARK: VIClientCallManagerDelegate
    
    func client(_ client: VIClient, didReceiveIncomingCall call: VICall, withIncomingVideo video: Bool, headers: [AnyHashable: Any]?) {
        if self.hasManagedCall() {
            // We don't need to invoke callKitReleaseAudioSession here
            call.reject(with: .busy, headers: nil)
        } else {
            let callinfo = CXCallUpdate()
            callinfo.remoteHandle = CXHandle(type: .generic, value: call.endpoints.first!.user!)
            callinfo.hasVideo = false
            callinfo.supportsHolding = true
            callinfo.supportsGrouping = false
            callinfo.supportsUngrouping = false
            callinfo.supportsDTMF = true
            callinfo.localizedCallerName = call.endpoints.first?.userDisplayName
            
            let newUUID = UUID()
            
            callProvider.reportNewIncomingCall(with: newUUID, update: callinfo)
            { [weak self] (error: Error?) in
                if let error = error {
                    // CallKit can reject new incoming call in the following cases:
                    // - "Do Not Disturb" mode is on
                    // - the caller is in the system black list
                    Log.e(error.localizedDescription)
                } else if let sself = self {
                    sself.managedCall = (call, uuid: newUUID, isOutgoing: false, hasConnected: false)
                }
            }
        }
    }
}
