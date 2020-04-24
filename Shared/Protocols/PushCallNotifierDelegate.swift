/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol PushCallNotifierDelegate: AnyObject {
    func didReceiveIncomingCall(
        _ uuid: UUID,
        from fullUsername: String,
        withDisplayName userDisplayName: String,
        withPushCompletion pushProcessingCompletion: (() -> Void)?
    )
}
