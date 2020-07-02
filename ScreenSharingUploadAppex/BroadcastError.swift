/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate let errorDomain = "ScreenSharingErrorDomain"

enum BroadcastError {
    static let noCall = NSError(
        domain: "ScreenSharingErrorDomain",
        code: 10000,
        userInfo: [NSLocalizedFailureReasonErrorKey: "Call is not started"]
    )
    
    static let nilOnCallInitialisation = NSError(
        domain: errorDomain,
        code: 10001,
        userInfo: [NSLocalizedFailureReasonErrorKey: "Internal broadcast error"]
    )
    
    static let authError = NSError(
        domain: errorDomain,
        code: 10002,
        userInfo: [NSLocalizedFailureReasonErrorKey: "Internal broadcast error"]
    )
    
    static let callEnded = NSError(
        domain: errorDomain,
        code: 10003,
        userInfo: [NSLocalizedFailureReasonErrorKey: "Call has been ended"]
    )
}
