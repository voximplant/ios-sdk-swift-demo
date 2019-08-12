/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import CallKit
import VoxImplant

// align CallKit API for transaction request for all iOS versions (>= 10.0):
// requestTransaction(with: completion:) was introduced in iOS 11
@available(iOS, introduced: 10.0, obsoleted: 11.0)
extension CXCallController {
    func requestTransaction(with action: CXAction, completion: @escaping (Error?) -> Void) {
        request(CXTransaction(action: action), completion: completion)
    }
}

extension CXCall {
    var info: VICall? {
        if let managedCall = sharedCallManager.managedCall,
           self.uuid == managedCall.uuid
        {
            return managedCall.0
        }
        
        return nil
    }
}
