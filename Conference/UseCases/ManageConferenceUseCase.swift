/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ManageConference {
    func sendVideo(_ send: Bool, completion: @escaping (Error?) -> Void)
    func mute(_ mute: Bool) throws
    func switchCamera()
    var conferenceDisconnectedHandler: ((Error?) -> Void)? { get set }
    var userAddedHandler: UserAdded? { get set }
    var userUpdatedHandler: UserUpdated? { get set }
    var videoStreamAddedHandler: VideoStreamAdded? { get set }
    var videoStreamRemovedHandler: VideoStreamRemoved? { get set }
    var userRemovedHandler: UserRemoved? { get set }
}

final class ManageConferenceUseCase: ManageConference {
    private var conferenceService: ConferenceService
    
    var userAddedHandler: UserAdded? {
        didSet {
            conferenceService.endpointAddedHandler = userAddedHandler
        }
    }
    var userUpdatedHandler: UserUpdated? {
        didSet {
            conferenceService.endpointUpdatedHandler = userUpdatedHandler
        }
    }
    var videoStreamAddedHandler: VideoStreamAdded? {
        didSet {
            conferenceService.localVideoStreamAddedHandler = videoStreamAddedHandler
            conferenceService.remoteVideoStreamAddedHandler = videoStreamAddedHandler
        }
    }
    var videoStreamRemovedHandler: VideoStreamRemoved? {
        didSet {
            conferenceService.localVideoStreamRemovedHandler = videoStreamRemovedHandler
            conferenceService.remoteVideoStreamRemovedHandler = videoStreamRemovedHandler
        }
    }
    var userRemovedHandler: UserRemoved? {
        didSet {
            conferenceService.endpointRemovedHandler = userRemovedHandler
        }
    }
    var conferenceDisconnectedHandler: ((Error?) -> Void)? {
        didSet {
            conferenceService.conferenceDisconnectedHandler = conferenceDisconnectedHandler
        }
    }
    
    required init(conferenceService: ConferenceService) {
        self.conferenceService = conferenceService
    }
    
    func sendVideo(_ send: Bool, completion: @escaping (Error?) -> Void) {
        conferenceService.sendVideo(send, completion: completion)
    }
    
    func mute(_ mute: Bool) throws {
        try conferenceService.mute(mute)
    }
    
    func switchCamera() {
        conferenceService.switchCamera()
    }
}
