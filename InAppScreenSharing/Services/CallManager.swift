/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import VoxImplantSDK

final class CallManager:
    NSObject,
    VIClientCallManagerDelegate,
    VIAudioManagerDelegate,
    VICallDelegate,
    VIEndpointDelegate
{
    typealias VideoStreamAdded = (_ local: Bool, (VIVideoRendererView) -> Void) -> Void
    typealias VideoStreamRemoved = (_ local: Bool) -> Void
    
    struct CallWrapper {
        fileprivate let call: VICall
        let callee: String
        var displayName: String?
        var state: CallState = .connecting
        let direction: CallDirection
        var sendingVideo: Bool = true
        var sharingScreen: Bool = false
        
        enum CallDirection {
            case incoming
            case outgoing
        }
        
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
    
    // Voximplant SDK supports multiple calls at the same time, however
    // this demo app demonstrates only one managed call at the moment,
    // so it rejects new incoming call if there is already a call.
    private(set) var managedCallWrapper: CallWrapper? {
        willSet {
            if managedCallWrapper?.call != newValue?.call {
                managedCallWrapper?.call.remove(self)
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
    
    var callObserver: ((CallWrapper) -> Void)?
    var didReceiveIncomingCall: (() -> Void)?
    var videoStreamAddedHandler: VideoStreamAdded?
    var videoStreamRemovedHandler: VideoStreamRemoved?
    
    private let callSettings: VICallSettings = {
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: true, sendVideo: true)
        return settings
    }()
    
    required init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        
        super.init()
        
        VIAudioManager.shared().delegate = self
        self.client.callManagerDelegate = self
    }
    
    func makeOutgoingCall(to contact: String) throws {
        guard authService.isLoggedIn else { throw AuthError.notLoggedIn }
        guard hasNoManagedCalls else { throw CallError.alreadyManagingACall }
        
        if let call = client.call(contact, settings: callSettings) {
            managedCallWrapper = CallWrapper(call: call, callee: contact, direction: .outgoing)
        } else {
            throw CallError.internalError
        }
    }
    
    func startOutgoingCall() throws {
        guard let call = managedCallWrapper?.call else { throw CallError.hasNoActiveCall }
        guard authService.isLoggedIn else { throw AuthError.notLoggedIn }
        
        if headphonesNotConnected {
            self.selectIfAvailable(.speaker, from: VIAudioManager.shared().availableAudioDevices())
        }
        call.start()
    }
    
    func makeIncomingCallActive() throws {
        guard let call = managedCallWrapper?.call else { throw CallError.hasNoActiveCall }
        guard authService.isLoggedIn else { throw AuthError.notLoggedIn }
        
        if headphonesNotConnected {
            selectIfAvailable(.speaker, from: VIAudioManager.shared().availableAudioDevices())
        }
        call.answer(with: callSettings)
    }
    
    func changeSendVideo(_ completion: ((Error?) -> Void)? = nil) {
        guard let wrapper = managedCallWrapper else { completion?(CallError.hasNoActiveCall); return }
        
        wrapper.call.setSendVideo(!wrapper.sendingVideo) { [weak self] error in
            if let error = error {
                completion?(error)
                return
            }
            
            self?.managedCallWrapper?.sendingVideo.toggle()
            self?.managedCallWrapper?.sharingScreen = false
            completion?(nil)
        }
    }
    
    func changeShareScreen(_ completion: ((Error?) -> Void)? = nil) {
        guard let wrapper = managedCallWrapper else { completion?(CallError.hasNoActiveCall); return }
        
        if wrapper.sharingScreen {
            wrapper.call.setSendVideo(wrapper.sendingVideo) { [weak self] error in
                if let error = error {
                    completion?(error)
                    return
                }
                self?.managedCallWrapper?.sharingScreen = false
            }
        } else {
            wrapper.call.startInAppScreenSharing { [weak self] error in
                if let error = error {
                    completion?(error)
                    return
                }
                self?.managedCallWrapper?.sharingScreen = true
            }
        }
    }
    
    func endCall() throws {
        guard let call = managedCallWrapper?.call else { throw CallError.hasNoActiveCall }
        
        call.hangup(withHeaders: nil)
    }

    // MARK: - VIClientCallManagerDelegate -
    func client(_ client: VIClient,
                didReceiveIncomingCall call: VICall,
                withIncomingVideo video: Bool,
                headers: [AnyHashable: Any]?
    ) {
        if hasManagedCall {
            call.reject(with: .busy, headers: nil)
        } else {
            managedCallWrapper = CallWrapper(call: call, callee: call.endpoints.first?.user ?? "", displayName: call.endpoints.first?.userDisplayName, direction: .incoming)
            didReceiveIncomingCall?()
        }
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
    }
    
    func call(_ call: VICall,
              didFailWithError error: Error,
              headers: [AnyHashable : Any]?
    ) {
        if call.callId == managedCallWrapper?.call.callId {
            managedCallWrapper?.state = .ended(reason: .failed(message: error.localizedDescription))
            managedCallWrapper = nil
        }
    }
    
    func call(_ call: VICall, didAddLocalVideoStream videoStream: VIVideoStream) {
        if videoStream.type == .screenSharing { return }
        videoStreamAddedHandler?(true) { renderer in
            videoStream.addRenderer(renderer)
        }
    }
    
    func call(_ call: VICall, didRemoveLocalVideoStream videoStream: VIVideoStream) {
        videoStreamRemovedHandler?(true)
        videoStream.removeAllRenderers()
    }
    
    func call(_ call: VICall, didAdd endpoint: VIEndpoint) {
        endpoint.delegate = self
    }
    
    // MARK: - VIEndpointDelegate -
    func endpoint(_ endpoint: VIEndpoint, didAddRemoteVideoStream videoStream: VIVideoStream) {
        videoStreamAddedHandler?(false) { renderer in
            videoStream.addRenderer(renderer)
        }
    }
    
    func endpoint(_ endpoint: VIEndpoint, didRemoveRemoteVideoStream videoStream: VIVideoStream) {
        videoStreamRemovedHandler?(false)
        videoStream.removeAllRenderers()
    }
    
    // MARK: - VIAudioManagerDelegate -
    func audioDeviceChanged(_ audioDevice: VIAudioDevice) { }
    
    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice) { }
    
    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>) {
        if headphonesNotConnected {
            selectIfAvailable(.speaker, from: availableAudioDevices)
        }
    }
    
    // MARK: - Private -
    private var headphonesNotConnected: Bool {
        !VIAudioManager.shared().availableAudioDevices().contains { $0.type == .wired || $0.type == .bluetooth }
    }
    
    private func selectIfAvailable(_ audioDeviceType: VIAudioDeviceType, from audioDevices: Set<VIAudioDevice>) {
        if let device = audioDevices.first(where: { $0.type == audioDeviceType }) {
            VIAudioManager.shared().select(device)
        }
    }
}
