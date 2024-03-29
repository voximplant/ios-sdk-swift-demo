/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import CallKit
import VoxImplantSDK

typealias VideoStreamAdded = (_ local: Bool, (VIVideoRendererView) -> Void) -> Void
typealias VideoStreamRemoved = (_ local: Bool) -> Void

final class CallManager:
    NSObject,
    CXProviderDelegate,
    VICallDelegate,
    VIClientCallManagerDelegate,
    VIEndpointDelegate,
    VIAudioManagerDelegate,
    PushCallNotifierDelegate,
    SpeakerAutoselecting
{
    private let client: VIClient
    private let authService: AuthService
    private let pushCallNotifier: PushCallNotifier
    private var audioIsActive: Bool = false
    
    // Voximplant SDK supports multiple calls at the same time, however
    // this demo app demonstrates only one managed call at the moment,
    // so it rejects new incoming call, if there is already a call.
    private(set) var managedCall: CallWrapper? {
        willSet {
            managedCall?.delegate = nil // old managedCall
        }
        didSet {
            managedCall?.delegate = self // new managedCall
        }
    }

    weak var reconnectDelegate: CallReconnectDelegate?
    var hasManagedCall: Bool { managedCall != nil }
    private var hasNoManagedCalls: Bool { !hasManagedCall }
    
    var videoStreamAddedHandler: VideoStreamAdded?
    var videoStreamRemovedHandler: VideoStreamRemoved?
    
    func info(of call: CXCall) -> VICall? {
        if let managedCall = self.managedCall,
           call.uuid == managedCall.uuid
        {
            return managedCall.call
        }
        
        return nil
    }
    
    private let callProvider: CXProvider = {
        let providerConfiguration = CXProviderConfiguration(localizedName: "VideoCallKit")
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.ringtoneSound = "noisecollector-beam.aiff"
        if let logo = UIImage(named: "CallKitLogo") {
            providerConfiguration.iconTemplateImageData = logo.pngData()
        }
        
        return CXProvider(configuration: providerConfiguration)
    }()
        
    fileprivate var progressTone: CXAudioFile? = {
        let progressTone = (name: "current_us_can", extension: "wav")
        if let progressTonePath = Bundle.main.path(forResource: progressTone.name, ofType: progressTone.extension) {
            return CXAudioFile(url: URL(fileURLWithPath: progressTonePath), looped: true)
        } else {
            return nil
        }
    }()
    
    fileprivate var reconnectTone: CXAudioFile? = {
            let reconnectTone = (name: "fennelliott-beeping", extension: "wav")
            if let reconnectTonePath = Bundle.main.path(forResource: reconnectTone.name, ofType: reconnectTone.extension) {
                return CXAudioFile(url: URL(fileURLWithPath: reconnectTonePath), looped: true)
            } else {
                return nil
            }
        }()

    required init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        self.pushCallNotifier = PushCallNotifier(client, authService)
        
        super.init()
        
        VIAudioManager.shared().delegate = self
        self.client.callManagerDelegate = self
        self.callProvider.setDelegate(self, queue: nil)
        self.pushCallNotifier.delegate = self
    }
    
    deinit {
        // According to the CXProvider documentation: "The provider must be invalidated before it is deallocated."
        callProvider.invalidate()
    }

    func endCall(_ uuid: UUID) {
        if let call = managedCall, call.uuid == uuid {
            if call.direction == .outgoing || call.hasStarted {
                call.call?.hangup(withHeaders: nil)
            } else {
                call.call?.reject(with: .decline, headers: nil)
            }
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
            self.videoStreamAddedHandler = nil
            self.videoStreamRemovedHandler = nil
            
            // callKitReleaseAudio should be called after deactivating CallKit session by iOS subsystem after the call ended.
            if !self.audioIsActive {
                VIAudioManager.shared().callKitReleaseAudioSession()
            }
        }
    }
    
    func updateOutgoingCall(_ vicall: VICall) {
        if let managedCall = self.managedCall,
           managedCall.call == nil,
           managedCall.uuid == vicall.callKitUUID
        {
            managedCall.call = vicall
            selectSpeaker()
            vicall.start()
            managedCall.hasStarted = true
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
        guard hasNoManagedCalls else { return }
        self.managedCall = CallWrapper(uuid: callUUID, direction: .outgoing)
    }
    
    func createIncomingCall(
        _ newUUID: UUID,
        from fullUsername: String,
        withDisplayName userDisplayName: String,
        withPushCompletion pushProcessingCompletion: (() -> Void)? = nil
    ) {
        guard hasNoManagedCalls else { return }

        self.managedCall = CallWrapper(uuid: newUUID, withPushCompletion: pushProcessingCompletion)
        
        let callinfo = CXCallUpdate()
        callinfo.remoteHandle = CXHandle(type: .generic, value: fullUsername)
        callinfo.supportsHolding = true
        callinfo.supportsGrouping = false
        callinfo.supportsUngrouping = false
        callinfo.supportsDTMF = false
        callinfo.hasVideo = true
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
    
    // MARK: - CXProviderDelegate -
    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        if authService.isLoggedIn {
            return false
        } else {
            if authService.state == .disconnected {
                authService.loginWithAccessToken()
                { [weak self] error in
                    guard let self = self else { return }
                    if error == nil {
                        self.callProvider.commitTransactions(self)
                    } else if let managedCallUUID = self.managedCall?.uuid {
                        self.reportCallEnded(managedCallUUID, .failed)
                    }
                }
            }
            return true
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard hasNoManagedCalls
        else {
            action.fail()
            Log.i("CallManager startcall: tried to start the call \(action.callUUID) while already managed the call \(String(describing: self.managedCall?.uuid))")
            return
        }
        createOutgoingCall(action.callUUID)
        Log.i("CallManager startcall: created new outgoing call \(action.callUUID)")
        
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: true, sendVideo: true)
        if let call: VICall = client.call(action.handle.value, settings: settings) {
            action.fulfill()
            call.callKitUUID = action.callUUID
            VIAudioManager.shared().callKitConfigureAudioSession(nil)
            self.updateOutgoingCall(call)
            Log.i("CallManager startcall: updated outgoing call \(call.callKitUUID!)")
        } else {
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStartAudio()
        audioIsActive = true
        progressTone?.didActivateAudioSession()
        reconnectTone?.didActivateAudioSession()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStopAudio()
        audioIsActive = false
        progressTone?.didDeactivateAudioSession()
        reconnectTone?.didDeactivateAudioSession()
        
        // callKitReleaseAudio should be called after deactivating CallKit session by iOS subsystem after the call ended.
        if self.managedCall == nil {
            VIAudioManager.shared().callKitReleaseAudioSession()
        }
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
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: true, sendVideo: true)
        selectSpeaker()
        managedCall?.call?.answer(with: settings)
        managedCall?.hasStarted = true
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
    
    // MARK: - VICallDelegate -
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        reportCallEnded(call.callKitUUID!, .failed)
        progressTone?.stop()
        reconnectTone?.stop()
    }
    
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        let endReason: CXCallEndedReason = answeredElsewhere.boolValue ? .answeredElsewhere : .remoteEnded
        reportCallEnded(call.callKitUUID!, endReason)
        progressTone?.stop()
        reconnectTone?.stop()
    }
    
    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable : Any]?) {
        if let managedCall = managedCall {
            if managedCall.direction == .outgoing {
                // notify CallKit that the outgoing call is connected
                callProvider.reportOutgoingCall(with: managedCall.uuid, connectedAt: nil)
                
                // apply the configuration to the CallKit call screen
                // for incoming calls this configuration is set, when the incoming call is reported to CallKit
                let callinfo = CXCallUpdate()
                callinfo.hasVideo = true
                callinfo.supportsHolding = true
                callinfo.supportsGrouping = false
                callinfo.supportsUngrouping = false
                callinfo.supportsDTMF = false
                callinfo.localizedCallerName = call.endpoints.first?.userDisplayName
                
                callProvider.reportCall(with: managedCall.uuid, updated: callinfo)
            }
            managedCall.hasConnected = true
        }
        managedCall?.completePushProcessing()
    }

    func call(_ call: VICall, startRingingWithHeaders headers: [AnyHashable : Any]?) {
        progressTone?.play()
    }
    
    func callDidStartAudio(_ call: VICall) {
        progressTone?.stop()
    }

    // MARK: - VIClientCallManagerDelegate -
    func client(_ client: VIClient, pushDidExpire callKitUUID: UUID) {
        reportCallEnded(callKitUUID, .failed)
    }
    
    func client(_ client: VIClient,
                didReceiveIncomingCall call: VICall,
                withIncomingVideo video: Bool,
                headers: [AnyHashable: Any]?
    ) {
        if let managedCall = managedCall {
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
    
    func callDidStartReconnecting(_ call: VICall) {
        if let managedCall = managedCall {
            reconnectDelegate?.callDidStartReconnecting(uuid: managedCall.uuid)
            progressTone?.stop()
            reconnectTone?.play()
        }
    }
    
    func callDidReconnect(_ call: VICall) {
        if let managedCall = managedCall {
            reconnectDelegate?.callDidReconnect(uuid: managedCall.uuid)
            reconnectTone?.stop()
            if !managedCall.hasConnected {
                progressTone?.play()
            }
        }
    }
    
    func call(_ call: VICall, didAddLocalVideoStream videoStream: VILocalVideoStream) {
        videoStreamAddedHandler?(true) { renderer in
            videoStream.addRenderer(renderer)
        }
    }
    
    func call(_ call: VICall, didRemoveLocalVideoStream videoStream: VILocalVideoStream) {
        videoStreamRemovedHandler?(true)
        videoStream.removeAllRenderers()
    }
    
    func call(_ call: VICall, didAdd endpoint: VIEndpoint) {
        endpoint.delegate = self
    }
    
    // MARK: - VIEndpointDelegate -
    func endpoint(_ endpoint: VIEndpoint, didAddRemoteVideoStream videoStream: VIRemoteVideoStream) {
        videoStreamAddedHandler?(false) { renderer in
            videoStream.addRenderer(renderer)
        }
    }
    
    func endpoint(_ endpoint: VIEndpoint, didRemoveRemoteVideoStream videoStream: VIRemoteVideoStream) {
        videoStreamRemovedHandler?(false)
        videoStream.removeAllRenderers()
    }

    // MARK: - PushCallNotifierDelegate -
    func didReceiveIncomingCall(_ newUUID: UUID,
                                from fullUsername: String,
                                withDisplayName userDisplayName: String,
                                withPushCompletion pushProcessingCompletion: (() -> Void)?
    ) {
        if hasManagedCall {
            // another call has been reported, skipped a new one:
            Log.i("CallManager push rcv: skipped new incoming call \(newUUID) while has already managed call \(String(describing: managedCall?.uuid))")
            return
        } else {
            createIncomingCall(newUUID, from: fullUsername, withDisplayName: userDisplayName, withPushCompletion: pushProcessingCompletion)
            Log.i("CallManager push rcv: created new incoming call \(newUUID)")
        }
        
        authService.loginWithAccessToken()
        { [reportedCallUUID = newUUID, weak self] error in
            if error != nil {
                self?.reportCallEnded(reportedCallUUID, .failed)
            }
            // in case of success we will receive VICall instance via VICallManagerDelegate
        }
    }
    
    // MARK: - VIAudioManagerDelegate -
    func audioDeviceChanged(_ audioDevice: VIAudioDevice) { }
    
    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice) { }
    
    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>) {
        selectSpeaker(from: availableAudioDevices)
    }
}
