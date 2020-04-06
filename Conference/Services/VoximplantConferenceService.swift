/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

typealias UserAdded = (String, String?) -> Void
typealias UserUpdated = (String, String?) -> Void
typealias UserRemoved = (String) -> Void
typealias VideoStreamAdded = (String, (VIVideoRendererView) -> Void) -> Void
typealias VideoStreamRemoved = (String) -> Void

protocol ConferenceService {
    func joinConference(withID id: String, sendVideo video: Bool) throws
    func leaveConference() throws
    func mute(_ mute: Bool) throws
    func sendVideo(_ send: Bool, completion: @escaping (Error?) -> Void)
    func switchCamera()
    var conferenceDisconnectedHandler: ((Error?) -> Void)? { get set }
    var endpointAddedHandler: UserAdded? { get set }
    var endpointUpdatedHandler: UserUpdated? { get set }
    var endpointRemovedHandler: UserRemoved? { get set }
    var localVideoStreamAddedHandler: VideoStreamAdded? { get set }
    var localVideoStreamRemovedHandler: VideoStreamRemoved? { get set }
    var remoteVideoStreamAddedHandler: VideoStreamAdded? { get set }
    var remoteVideoStreamRemovedHandler: VideoStreamRemoved? { get set }
}

let myId = "me"

final class VoximplantConferenceService: NSObject, ConferenceService, VICallDelegate, VIEndpointDelegate {
    private let client: VIClient
    private var managedConference: VICall?
    
    var endpointAddedHandler: UserAdded?
    var endpointUpdatedHandler: UserUpdated?
    var endpointRemovedHandler: UserRemoved?
    var localVideoStreamAddedHandler: VideoStreamAdded?
    var localVideoStreamRemovedHandler: VideoStreamRemoved?
    var remoteVideoStreamAddedHandler: VideoStreamAdded?
    var remoteVideoStreamRemovedHandler: VideoStreamRemoved?
    var conferenceDisconnectedHandler: ((Error?) -> Void)?
    
    required init(client: VIClient) {
        self.client = client
    }
    
    func joinConference(withID id: String, sendVideo video: Bool) throws {
        let conferenceName = "conf_\(id)"
        let settings = VICallSettings()
        settings.preferredVideoCodec = .VP8
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: true, sendVideo: video)
        let conference = client.callConference(conferenceName, settings: settings)
        self.managedConference = conference
        
        try callOrThrow().start()
        VIAudioManager.shared()?.select(VIAudioDevice(type: .speaker))
        try callOrThrow().add(self)
    }
    
    func leaveConference() throws {
        try callOrThrow().hangup(withHeaders: nil)
    }
    
    func mute(_ mute: Bool) throws {
        try callOrThrow().sendAudio = !mute
    }
    
    func sendVideo(_ send: Bool, completion: @escaping (Error?) -> Void) {
        if let call = managedConference {
            call.setSendVideo(send, completion: completion)
        } else {
            completion(Errors.noActiveConferenceFound)
        }
    }
    
    func switchCamera() {
        VICameraManager.shared().useBackCamera.toggle()
    }
    
    private func callOrThrow() throws -> VICall {
        if let call = managedConference {
            return call
        } else {
            throw Errors.noActiveConferenceFound
        }
    }
    
    // MARK: - VICallDelegate -
    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable : Any]?) {
        managedConference = call
    }
    
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        managedConference = nil
        conferenceDisconnectedHandler?(nil)
    }
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        managedConference = nil
        conferenceDisconnectedHandler?(error)
    }
    
    func call(_ call: VICall, didAddLocalVideoStream videoStream: VIVideoStream) {
        localVideoStreamAddedHandler?(myId) { renderer in
            videoStream.addRenderer(renderer)
        }
    }
    
    func call(_ call: VICall, didRemoveLocalVideoStream videoStream: VIVideoStream) {
        localVideoStreamRemovedHandler?(myId)
        videoStream.removeAllRenderers()
    }
    
    func call(_ call: VICall, didAdd endpoint: VIEndpoint) {
        if endpoint.endpointId == managedConference?.callId {
            return
        }
        endpoint.delegate = self
        endpointAddedHandler?(endpoint.endpointId, endpoint.userDisplayName ?? endpoint.user)
    }
    
    // MARK: - VIEndpointDelegate -
    func endpointInfoDidUpdate(_ endpoint: VIEndpoint) {
        if endpoint.endpointId == managedConference?.callId {
            return
        }
        endpointUpdatedHandler?(endpoint.endpointId, endpoint.userDisplayName ?? endpoint.user)
    }
    
    func endpointDidRemove(_ endpoint: VIEndpoint) {
        endpoint.delegate = nil
        endpointRemovedHandler?(endpoint.endpointId)
    }
    
    func endpoint(_ endpoint: VIEndpoint, didAddRemoteVideoStream videoStream: VIVideoStream) {
        remoteVideoStreamAddedHandler?(endpoint.endpointId) { renderer in
            videoStream.addRenderer(renderer)
        }
    }
    
    func endpoint(_ endpoint: VIEndpoint, didRemoveRemoteVideoStream videoStream: VIVideoStream) {
        remoteVideoStreamRemovedHandler?(endpoint.endpointId)
        videoStream.removeAllRenderers()
    }
}
