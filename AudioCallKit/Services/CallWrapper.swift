/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class CallWrapper {
    var direction: Direction
    var hasConnected: Bool = false
    
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
    
    private var pushProcessingCompletion: (() -> Void)?
    func completePushProcessing() {
        self.pushProcessingCompletion?()
        self.pushProcessingCompletion = nil
    }
        
    private var uuidOnInit: UUID
    var uuid: UUID {
        if let call = self.call {
            return call.callKitUUID!
        } else {
            return uuidOnInit
        }
    }
    
    private var answerSettings: VICallSettings?
    
    // Always nil on CallWrapper initialization
    // It allows to handle the cases when the call can be reported to CallKit before the user is logged in, for example, the app received a VoIP push or a call is made from Recent Calls etc
    var call: VICall? {
        willSet {
            assert(call == nil)
            assert(newValue?.callKitUUID == uuidOnInit)
            if let delegate = delegate {
                call?.remove(delegate)
            }
        }
        didSet {
            if let delegate = delegate {
                call?.add(delegate)
            }
            if let settings = answerSettings, direction == .incoming {
                call?.answer(with: settings)
                answerSettings = nil
            }
        }
    }
    
    func answer(with settings: VICallSettings) {
        if let call = call {
            call.answer(with: settings)
        } else {
            answerSettings = settings
        }
    }
    
    init(uuid: UUID, withPushCompletion pushProcessingCompletion: (() -> Void)?) {
        self.direction = .incoming
        self.uuidOnInit = uuid
        self.pushProcessingCompletion = pushProcessingCompletion
    }
    
    init(uuid: UUID, direction: Direction) {
        self.direction = direction
        self.uuidOnInit = uuid
    }
    
    enum Direction {
        case incoming
        case outgoing
    }
}
