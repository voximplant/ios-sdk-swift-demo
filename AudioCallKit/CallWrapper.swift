/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplantSDK

class CallWrapper {
    var isOutgoing: Bool
    var hasConnected: Bool = false
    fileprivate var pushProcessingCompletion: (()->Void)?
    weak var delegate: VICallDelegate? {
        willSet {
            if let delegate = self.delegate {
                call?.remove(delegate)
            }
        }
        didSet {
            if let delegate = self.delegate {
                call?.add(delegate)
            }
        }
    }
    
    func completePushProcessing() {
        self.pushProcessingCompletion?()
        self.pushProcessingCompletion = nil
    }
        
    fileprivate var uuidOnInit: UUID
    var uuid: UUID {
        if let call = self.call {
            return call.callKitUUID!
        } else {
            return uuidOnInit
        }
    }
    
    // Always nil on CallWrapper initialization
    // It allows to handle the cases when the call can be reported to CallKit before the user is logged in, for example, the app received a VoIP push or a call is made from Recent Calls etc
    var call: VICall? {
        willSet {
            assert(call == nil)
            assert(newValue?.callKitUUID == uuidOnInit)
            if let delegate = self.delegate {
                call?.remove(delegate)
            }
        }
        didSet {
            if let delegate = self.delegate {
                call?.add(delegate)
            }
        }
    }
    
    init(uuid: UUID, isOutgoing: Bool, withPushCompletion pushProcessingCompletion: (()->Void)?) {
        self.isOutgoing = false
        self.uuidOnInit = uuid
        self.pushProcessingCompletion = pushProcessingCompletion
    }
    
    init(uuid: UUID, isOutgoing: Bool) {
        self.isOutgoing = isOutgoing
        self.uuidOnInit = uuid
    }
}
