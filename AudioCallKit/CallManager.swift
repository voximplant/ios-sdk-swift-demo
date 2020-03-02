/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK
import CallKit

class CallManager: NSObject, CXProviderDelegate, VICallDelegate, VIClientCallManagerDelegate, PushCallNotifierDelegate {
    fileprivate var client: VIClient
    fileprivate var authService: AuthService
    fileprivate var pushCallNotifier: PushCallNotifier
    
    // Voximplant SDK supports multiple calls at the same time, however
    // this demo app demonstrates only one managed call at the moment,
    // so it rejects new incoming call, if there is already a call.
    fileprivate(set) var managedCall: CallWrapper?
    {
        willSet {
            managedCall?.delegate = nil // old managedCall
        }
        didSet {
            managedCall?.delegate = self // new managedCall
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
        providerConfiguration.ringtoneSound = "noisecollector-beam.aiff"
        if let logo = UIImage(named: "CallKitLogo") {
            providerConfiguration.iconTemplateImageData = logo.pngData()
        }
        
        return CXProvider(configuration: providerConfiguration)
    }()
        
    fileprivate var progresstone: CXAudioFile? = {
        let progresstone = (name: "fennelliott-beeping", extension: "wav")
        if let progresstonePath = Bundle.main.path(forResource: progresstone.name, ofType: progresstone.extension) {
            return CXAudioFile(url: URL(fileURLWithPath: progresstonePath), looped: true)
        } else {
            return nil
        }
    }()

    init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        self.pushCallNotifier = PushCallNotifier(client, authService)
        
        super.init()
        
        self.client.callManagerDelegate = self
        self.callProvider.setDelegate(self, queue: nil)
        self.pushCallNotifier.delegate = self
    }
    
    deinit {
        // According to the CXProvider documentation: "The provider must be invalidated before it is deallocated."
        callProvider.invalidate()
    }
    
    // MARK: CXProviderDelegate
    func endCall(_ uuid: UUID) {
        if let call = managedCall, call.uuid == uuid {
            if !call.hasConnected && !call.isOutgoing {
                call.call?.reject(with: .decline, headers: nil)
            } else {
                call.call?.hangup(withHeaders: nil)
            }
            
            VIAudioManager.shared().callKitStopAudio()
            VIAudioManager.shared().callKitReleaseAudioSession()
        }
        // SDK will invoke VICallDelegate methods (didDisconnectWithHeaders or didFailWithError)
    }
    
    func reportCallEnded(_ uuid: UUID, _ endReason: CXCallEndedReason) {
        if let managedCall = self.managedCall, managedCall.uuid == uuid {
            let pendingActions: [CXAction] = callProvider.pendingCallActions(of: CXAction.self, withCall: uuid)
            if !pendingActions.isEmpty {
                // no matter what the endReason is
                pendingActions.forEach({ $0.fail() })
            } else {
                callProvider.reportCall(with: managedCall.uuid, endedAt: Date(), reason: endReason)
            }
            
            // Ensure the push processing is completed in cases:
            // 1. login issues
            // 2. call is rejected before the user is logged in
            // in all other cases completePushProcessing should be called in VICallDelegate methods
            self.managedCall?.completePushProcessing()
            
            self.managedCall = nil
        }
    }
    
    func updateOutgoingCall(_ vicall: VICall) {
        if let managedCall = self.managedCall,
           managedCall.call == nil,
           managedCall.uuid == vicall.callKitUUID
        {
            managedCall.call = vicall
            vicall.start()
            callProvider.reportOutgoingCall(with: managedCall.uuid, startedConnectingAt: nil)
        }
    }

    func updateIncomingCall(_ vicall: VICall) {
        if let managedCall = self.managedCall,
           managedCall.call == nil,
           managedCall.uuid == vicall.callKitUUID
        {
            managedCall.call = vicall
        }
    }
    
    func createOutgoingCall(_ callUUID: UUID) {
        guard !self.hasManagedCall() else { return }
        self.managedCall = CallWrapper(uuid: callUUID, isOutgoing: true)
    }
        
    func createIncomingCall(_ newUUID: UUID, from fullUsername: String, withDisplayName userDisplayName: String, withPushCompletion pushProcessingCompletion: (()->Void)? = nil) {
        guard !self.hasManagedCall() else { return }

        self.managedCall = CallWrapper(uuid: newUUID, isOutgoing: false, withPushCompletion: pushProcessingCompletion)
        
        let callinfo = CXCallUpdate()
        callinfo.remoteHandle = CXHandle(type: .generic, value: fullUsername)
        callinfo.supportsHolding = true
        callinfo.supportsGrouping = false
        callinfo.supportsUngrouping = false
        callinfo.supportsDTMF = true
        callinfo.hasVideo = false
        callinfo.localizedCallerName = userDisplayName
        
        callProvider.reportNewIncomingCall(with: newUUID, update: callinfo)
        { [reportedCallUUID = newUUID, weak self]
          (error: Error?) in
            if let error = error {
                Log.e("reportNewIncomingCall error - \(error.localizedDescription)")
                // CallKit can reject new incoming call in the following cases (CXErrorCodeIncomingCallError):
                // - "Do Not Disturb" mode is on
                // - the caller is in the system black list
                // - ...
                self?.endCall(reportedCallUUID)
            }
        }
    }
    
    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        if authService.state == .loggedIn {
            return false
        } else {
            if authService.state == .disconnected {
                authService.loginWithAccessToken()
                { [weak self] (result: Result<String, Error>) in
                    guard let sself = self else { return }
                    if case .success(_) = result {
                        sself.callProvider.commitTransactions(sself)
                    } else if let managedCallUUID = sself.managedCall?.uuid {
                        sself.reportCallEnded(managedCallUUID, .failed)
                    }
                }
            }
            return true
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard !self.hasManagedCall()
        else {
            action.fail()
            Log.i("CallManager startcall: tried to start the call \(action.callUUID) while already managed the call \(String(describing: self.managedCall?.uuid))")
            return
        }
        createOutgoingCall(action.callUUID)
        Log.i("CallManager startcall: created new outgoing call \(action.callUUID)")
        
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
        if let call: VICall = client.call(action.handle.value, settings: settings) {
            call.callKitUUID = action.callUUID
            VIAudioManager.shared().callKitConfigureAudioSession(nil)
            self.updateOutgoingCall(call)
            Log.i("CallManager startcall: updated outgoing call \(call.callKitUUID!)")
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStartAudio()
        progresstone?.didActivateAudioSession()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStopAudio()
        progresstone?.didDeactivateAudioSession()
    }

    // method caused by the CXProvider.invalidate()
    func providerDidReset(_ provider: CXProvider) {
        if let uuid = self.managedCall?.uuid {
            endCall(uuid)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        VIAudioManager.shared().callKitConfigureAudioSession(nil)
        
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
        managedCall?.call?.answer(with: settings)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        managedCall?.call?.setHold(action.isOnHold)
        { error in
            if let error = error {
                Log.e(error.localizedDescription)
                action.fail()
            } else {
                action.fulfill()
            }
        }
    }
    
    // the method is called if the user rejects an incoming call or hangup an active call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        endCall(action.callUUID)
        action.fulfill(withDateEnded: Date())
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        managedCall?.call?.sendDTMF(action.digits)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        managedCall?.call?.sendAudio = !action.isMuted
        action.fulfill()
    }
    
    // MARK: VICallDelegate
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        reportCallEnded(call.callKitUUID!, .failed)
        
        progresstone?.stop()
        
        self.managedCall?.completePushProcessing()
    }
    
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        let endReason: CXCallEndedReason = answeredElsewhere.boolValue ? .answeredElsewhere : .remoteEnded
        reportCallEnded(call.callKitUUID!, endReason)
        
        progresstone?.stop()
        
        self.managedCall?.completePushProcessing()
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
        
        self.managedCall?.completePushProcessing()
    }

    func call(_ call: VICall, startRingingWithHeaders headers: [AnyHashable : Any]?) {
        progresstone?.play()
    }
    
    func callDidStartAudio(_ call: VICall) {
        progresstone?.stop()
    }

    // MARK: VIClientCallManagerDelegate
    
    func client(_ client: VIClient, pushDidExpire callKitUUID: UUID) {
        reportCallEnded(callKitUUID, .failed)
    }
    
    func client(_ client: VIClient, didReceiveIncomingCall call: VICall, withIncomingVideo video: Bool, headers: [AnyHashable: Any]?) {
        
        if let managedCall = self.managedCall {
            if managedCall.uuid == call.callKitUUID {
                updateIncomingCall(call)
                callProvider.commitTransactions(self)
                Log.i("CallManager  sdk rcv: updated already managed incoming call \(call.callKitUUID!)")
            } else {
                // another call has been reported, reject a new one:
                call.reject(with: .decline, headers: nil)
                Log.i("CallManager  sdk rcv: rejected new incoming call \(call.callKitUUID!) while has already managed call \(managedCall.uuid)")
            }
        } else {
            createIncomingCall(call.callKitUUID!, from: call.endpoints.first!.user!, withDisplayName: call.endpoints.first!.userDisplayName!)
            updateIncomingCall(call)
            Log.i("CallManager  sdk rcv: created and updated new incoming call \(call.callKitUUID!)")
        }
    }

    // MARK: PushCallNotifierDelegate
    
    func didReceiveIncomingCall(_ newUUID: UUID, from fullUsername: String, withDisplayName userDisplayName: String, withPushCompletion pushProcessingCompletion: (()->Void)?) {
        if self.hasManagedCall() {
            // another call has been reported, skipped a new one:
            Log.i("CallManager push rcv: skipped new incoming call \(newUUID) while has already managed call \(String(describing: self.managedCall?.uuid))")
            return
        } else {
            createIncomingCall(newUUID, from: fullUsername, withDisplayName: userDisplayName, withPushCompletion: pushProcessingCompletion)
            Log.i("CallManager push rcv: created new incoming call \(newUUID)")
        }
        
        authService.loginWithAccessToken()
        { [reportedCallUUID = newUUID, weak self]
          (result: Result<String, Error>) in
            guard let sself = self else { return }
            if case .failure(_) = result {
                sself.reportCallEnded(reportedCallUUID, .failed)
            }
            // in case of success we will receive VICall instance via VICallManagerDelegate
        }
    }
}
