/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import VoxImplantSDK
import ReplayKit

let myId = "me"

final class CallManager:
    NSObject,
    VIClientCallManagerDelegate,
    VIAudioManagerDelegate,
    VICallDelegate,
    VIEndpointDelegate,
    SpeakerAutoselecting
{
    typealias UserAdded = (String, String?) -> Void
    typealias UserUpdated = (String, String?) -> Void
    typealias UserRemoved = (String) -> Void
    typealias VideoStreamAdded = (String, (VIVideoRendererView?) -> Void) -> Void
    typealias VideoStreamRemoved = (String) -> Void
    
    struct CallWrapper {
        fileprivate let call: VICall
        let callee: String
        var displayName: String?
        var state: CallState = .connecting
        var sendingVideo: Bool = true
        var sharingScreen: Bool = false
        
        enum CallState: Equatable {
            case connecting
            case connected
            case ended (reason: CallEndReason)
            
            enum CallEndReason: Equatable {
                case disconnected
                case failed (message: String)
            }
        }
    }
    
    private let client: VIClient
    private let authService: AuthService
    private let notificationCenter: DarwinNotificationCenter
    
    @UserDefault("activecall")
    private var managedCallee: String?
    
    // Voximplant SDK supports multiple calls at the same time, however
    // this demo app demonstrates only one managed call at the moment,
    // so it rejects new incoming call if there is already a call.
    private(set) var managedCallWrapper: CallWrapper? {
        willSet { 
            if managedCallWrapper?.call != newValue?.call {
                managedCallWrapper?.call.remove(self)
                self.managedCallee = newValue?.callee
            }
        }
        didSet {
            if let newValue = managedCallWrapper {
                callObserver?(newValue)
            }
            if managedCallWrapper?.call != oldValue?.call {
                managedCallWrapper?.call.add(self)
            }
        }
    }
    var hasManagedCall: Bool { managedCallWrapper != nil }
    private var hasNoManagedCalls: Bool { !hasManagedCall }
    
    var endpointAddedHandler: UserAdded?
    var endpointUpdatedHandler: UserUpdated?
    var endpointRemovedHandler: UserRemoved?
    var localVideoStreamAddedHandler: VideoStreamAdded?
    var localVideoStreamRemovedHandler: VideoStreamRemoved?
    var remoteVideoStreamAddedHandler: VideoStreamAdded?
    var remoteVideoStreamRemovedHandler: VideoStreamRemoved?
    var callObserver: ((CallWrapper) -> Void)?
    
    private let callSettings: VICallSettings = {
        let settings = VICallSettings()
        settings.preferredVideoCodec = .H264
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: true, sendVideo: true)
        return settings
    }()
    
    init(_ client: VIClient,
         _ authService: AuthService,
         _ notificationCenter: DarwinNotificationCenter
    ) {
        self.client = client
        self.authService = authService
        self.notificationCenter = notificationCenter
        
        super.init()
        
        self.notificationCenter.registerForNotification(.broadcastEnded)
        self.notificationCenter.broadcastEndedHandler = {
            if let call = self.managedCallWrapper, call.sharingScreen {
                self.managedCallWrapper?.sharingScreen = false
            }
        }
        
        self.notificationCenter.registerForNotification(.broadcastStarted)
        self.notificationCenter.broadcastStartedHandler = {
            if let call = self.managedCallWrapper, !call.sharingScreen {
                self.managedCallWrapper?.sharingScreen = true
            }
        }
        
        self.notificationCenter.registerForNotification(.broadcastCallEnded)
        self.notificationCenter.broadcastCallEndedHandler = {
            if let call = self.managedCallWrapper, call.sharingScreen {
                self.managedCallWrapper?.sharingScreen = false
                AlertHelper.showAlert(
                    title: "Broadcast",
                    message: "Broadcast has been ended",
                    defaultAction: true
                )
            }
        }
        
        VIAudioManager.shared().delegate = self
        self.client.callManagerDelegate = self
    }
    
    func makeOutgoingCall(to contact: String) throws {
        guard authService.isLoggedIn else { throw AuthError.notLoggedIn }
        guard hasNoManagedCalls else { throw CallError.alreadyManagingACall }
        
        if let call = client.callConference(contact, settings: callSettings) {
            managedCallWrapper = CallWrapper(call: call, callee: contact)
        } else {
            throw CallError.internalError
        }
    }
    
    func startOutgoingCall() throws {
        guard let call = managedCallWrapper?.call else { throw CallError.hasNoActiveCall }
        guard authService.isLoggedIn else { throw AuthError.notLoggedIn }
        
        selectSpeaker()
        call.start()
    }
    
    func toggleSendVideo(_ completion: @escaping (Error?) -> Void) {
        guard let wrapper = managedCallWrapper else {
            completion(CallError.hasNoActiveCall)
            return
        }
        wrapper.call.setSendVideo(!wrapper.sendingVideo) { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            self?.managedCallWrapper?.sendingVideo.toggle()
            self?.managedCallWrapper?.sharingScreen = false
            completion(nil)
        }
    }
    
    func endCall() throws {
        guard let call = managedCallWrapper?.call else {
            throw CallError.hasNoActiveCall
        }
        call.hangup(withHeaders: nil)
    }

    // MARK: - VIClientCallManagerDelegate -
    func client(_ client: VIClient,
                didReceiveIncomingCall call: VICall,
                withIncomingVideo video: Bool,
                headers: [AnyHashable: Any]?
    ) {
        // Incoming calls are not supported in this demo
        call.reject(with: .busy, headers: nil)
    }
    
    // MARK: - VICallDelegate -
    func call(_ call: VICall,
              didConnectWithHeaders headers: [AnyHashable : Any]?
    ) {
        if call.callId == managedCallWrapper?.call.callId {
            managedCallWrapper?.displayName = call.endpoints.first?.userDisplayName ?? call.endpoints.first?.user
            managedCallWrapper?.state = .connected
        }
    }
    
    func call(_ call: VICall,
              didDisconnectWithHeaders headers: [AnyHashable: Any]?,
              answeredElsewhere: NSNumber
    ) {
        if call.callId == managedCallWrapper?.call.callId {
            managedCallWrapper?.state = .ended(reason: .disconnected)
            managedCallWrapper = nil
        }
        notificationCenter.sendNotification(.callEnded)
    }
    
    func call(_ call: VICall,
              didFailWithError error: Error,
              headers: [AnyHashable : Any]?
    ) {
        if call.callId == managedCallWrapper?.call.callId {
            managedCallWrapper?.state = .ended(reason: .failed(message: error.localizedDescription))
            managedCallWrapper = nil
        }
        notificationCenter.sendNotification(.callEnded)
    }

    func call(_ call: VICall, didAddLocalVideoStream videoStream: VILocalVideoStream) {
        if videoStream.type == .screenSharing { return }
        localVideoStreamAddedHandler?(myId) { renderer in
            if let renderer = renderer {
                videoStream.addRenderer(renderer)
            }
        }
    }

    func call(_ call: VICall, didRemoveLocalVideoStream videoStream: VILocalVideoStream) {
        localVideoStreamRemovedHandler?(myId)
        videoStream.removeAllRenderers()
    }
    
    func call(_ call: VICall, didAdd endpoint: VIEndpoint) {
        if endpoint.endpointId == call.callId {
            return
        }
        endpoint.delegate = self
        endpointAddedHandler?(endpoint.endpointId, endpoint.userDisplayName ?? endpoint.user)
    }
    
    // MARK: - VIEndpointDelegate -
    func endpointInfoDidUpdate(_ endpoint: VIEndpoint) {
        if endpoint.endpointId == managedCallWrapper?.call.callId {
            return
        }
        endpointUpdatedHandler?(endpoint.endpointId, endpoint.userDisplayName ?? endpoint.user)
    }
    
    func endpointDidRemove(_ endpoint: VIEndpoint) {
        endpointRemovedHandler?(endpoint.endpointId)
    }

    func endpoint(_ endpoint: VIEndpoint, didAddRemoteVideoStream videoStream: VIRemoteVideoStream) {
        remoteVideoStreamAddedHandler?(endpoint.endpointId) { renderer in
            if let renderer = renderer {
                videoStream.addRenderer(renderer)
            }
        }
    }

    func endpoint(_ endpoint: VIEndpoint, didRemoveRemoteVideoStream videoStream: VIRemoteVideoStream) {
        remoteVideoStreamRemovedHandler?(endpoint.endpointId)
        videoStream.removeAllRenderers()
    }

    // MARK: - VIAudioManagerDelegate -
    func audioDeviceChanged(_ audioDevice: VIAudioDevice) { }
    
    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice) { }
    
    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>) {
        selectSpeaker(from: availableAudioDevices)
    }
}
