/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class CallManager:
    NSObject,
    VIClientCallManagerDelegate,
    VICallDelegate
{
    struct CallWrapper {
        fileprivate let call: VICall
        let callee: String
        var displayName: String?
        var state: CallState = .connecting
        var previousState: CallState = .connecting
        let direction: CallDirection
        var duration: TimeInterval {
            call.duration()
        }
        var isMuted: Bool = false
        var isOnHold: Bool = false
        
        enum CallDirection {
            case incoming
            case outgoing
        }
        
        enum CallState: Equatable {
            case connecting
            case ringing
            case connected
            case reconnecting
            case ended (reason: CallEndReason)
            
            enum CallEndReason: Equatable {
                case disconnected
                case failed (message: String)
            }
        }
    }

    private var client: VIClient
    private var authService: AuthService
    
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
    
    private let callSettings: VICallSettings = {
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
        return settings
    }()
    
    fileprivate var ringtone: LoudAudioFile? = {
        let ringtone = (name: "noisecollector-beam", extension: "aiff")
        if let ringtonePath = Bundle.main.path(forResource: ringtone.name, ofType: ringtone.extension) {
            return LoudAudioFile(url: URL(fileURLWithPath: ringtonePath), looped: true)
        } else {
            return nil
        }
    }()
    
    fileprivate var progressTone: VIAudioFile? = {
        let progressTone = (name: "current_us_can", extension: "wav")
        if let progressTonePath = Bundle.main.path(forResource: progressTone.name, ofType: progressTone.extension) {
            return VIAudioFile(url: URL(fileURLWithPath: progressTonePath), looped: true)
        } else {
            return nil
        }
    }()
    
    fileprivate var reconnectTone: VIAudioFile? = {
        let reconnectTone = (name: "fennelliott-beeping", extension: "wav")
        if let reconnectTonePath = Bundle.main.path(forResource: reconnectTone.name, ofType: reconnectTone.extension) {
            return VIAudioFile(url: URL(fileURLWithPath: reconnectTonePath), looped: true)
        } else {
            return nil
        }
    }()
    
    init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        super.init()
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
        
        call.start()
    }
    
    func makeIncomingCallActive() throws {
        guard let call = managedCallWrapper?.call else { throw CallError.hasNoActiveCall }
        guard authService.isLoggedIn else { throw AuthError.notLoggedIn }
        ringtone?.stop()
        call.answer(with: callSettings)
        if managedCallWrapper?.state == .reconnecting {
            reconnectTone?.play()
        }
    }
    
    func toggleMute() throws {
        guard let wrapper = managedCallWrapper else {
            throw CallError.hasNoActiveCall
        }
        wrapper.call.sendAudio = wrapper.isMuted
        managedCallWrapper?.isMuted.toggle()
    }
    
    func toggleHold(_ completion: @escaping (Error?) -> Void) {
        guard let wrapper = managedCallWrapper else {
            completion(CallError.hasNoActiveCall)
            return
        }
        wrapper.call.setHold(!wrapper.isOnHold) { [weak self] error in
            if let error = error {
                Log.e(error.localizedDescription)
                completion(error)
            } else {
                self?.managedCallWrapper?.isOnHold.toggle()
                completion(nil)
            }
        }
    }
    
    func sendDTMF(_ symbol: String) throws {
        guard let wrapper = managedCallWrapper else {
            throw CallError.hasNoActiveCall
        }
        wrapper.call.sendDTMF(symbol)
    }
    
    func endCall() throws {
        guard let call = managedCallWrapper?.call else {
            throw CallError.hasNoActiveCall
        }
        call.hangup(withHeaders: nil)
    }
    
    func rejectCall() throws {
        guard let call = managedCallWrapper?.call else {
            throw CallError.hasNoActiveCall
        }
        call.reject(with: VIRejectMode.decline, headers: nil)
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
            ringtone?.configureAudioBeforePlaying()
            ringtone?.play()
        }
    }
    
    
    // MARK: - VICallDelegate -
    func call(_ call: VICall,
              didConnectWithHeaders headers: [AnyHashable : Any]?
    ) {
        if let wrapper = managedCallWrapper, call.callId == wrapper.call.callId {
            managedCallWrapper?.displayName = call.endpoints.first?.userDisplayName ?? call.endpoints.first?.user
            managedCallWrapper?.previousState = wrapper.state
            managedCallWrapper?.state = .connected
        }
    }
    
    func callDidStartReconnecting(_ call: VICall) {
        if let wrapper = managedCallWrapper, call.callId == wrapper.call.callId {
            managedCallWrapper?.previousState = wrapper.state
            managedCallWrapper?.state = .reconnecting
            progressTone?.stop()
            if managedCallWrapper?.direction == .outgoing ||
                managedCallWrapper?.previousState == .connected {
                reconnectTone?.play()
            }
        }
    }
    
    func callDidReconnect(_ call: VICall) {
        if call.callId == managedCallWrapper?.call.callId {
            reconnectTone?.stop()
            switch managedCallWrapper?.previousState {
            case .connecting:
                managedCallWrapper?.state = .connecting
            case .ringing:
                managedCallWrapper?.state = .ringing
                progressTone?.play()
            case .connected:
                managedCallWrapper?.state = .connected
            default: break
            }
        }
    }
    
    func call(_ call: VICall,
              didDisconnectWithHeaders headers: [AnyHashable: Any]?,
              answeredElsewhere: NSNumber
    ) {
        if let wrapper = managedCallWrapper, call.callId == wrapper.call.callId {
            managedCallWrapper?.previousState = wrapper.state
            managedCallWrapper?.state = .ended(reason: .disconnected)
            managedCallWrapper = nil
            ringtone?.stop()
            progressTone?.stop()
            reconnectTone?.stop()
        }
    }
    
    func call(_ call: VICall,
              didFailWithError error: Error,
              headers: [AnyHashable : Any]?
    ) {
        if let wrapper = managedCallWrapper, call.callId == wrapper.call.callId {
            managedCallWrapper?.previousState = wrapper.state
            managedCallWrapper?.state = .ended(reason: .failed(message: error.localizedDescription))
            managedCallWrapper = nil
            ringtone?.stop()
            progressTone?.stop()
            reconnectTone?.stop()
        }
    }
    
    func call(_ call: VICall,
              startRingingWithHeaders headers: [AnyHashable : Any]?
    ) {
        if let wrapper = managedCallWrapper, call.callId == wrapper.call.callId {
            managedCallWrapper?.previousState = wrapper.state
            managedCallWrapper?.state = .ringing
            progressTone?.play()
        }
    }
    
    func callDidStartAudio(_ call: VICall) {
        progressTone?.stop()
    }
}
