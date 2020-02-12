/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplantSDK

protocol CallManagerDelegate {

}

protocol CallManager : VICallDelegate {
    var activeCall: CallDescriptor? { get }
    var pendingCall: CallDescriptor? { get }

    var registeredCalls: [UUID: CallDescriptor]! { get }

    func call(uuid: UUID!) -> CallDescriptor?
    func call(call: VICall!) -> CallDescriptor?

    func registerCallManager() -> Void

    func registerCall(_ descriptor: CallDescriptor!) -> Void
    func startCall(_ descriptor: CallDescriptor!) -> Void
    func endCall(_ descriptor: CallDescriptor!) -> Void
}

class CallDescriptor {
    var call: VICall!
    var uuid: UUID!
    var withVideo: Bool!
    var incoming: Bool!
    var started = false

    init(call: VICall!, uuid: UUID!, video: Bool!, incoming: Bool!) {
        self.call = call
        self.uuid = uuid
        self.withVideo = video
        self.incoming = incoming
    }
}
