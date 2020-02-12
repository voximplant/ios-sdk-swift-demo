/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplantSDK

let AudioCallErrorDomain = Bundle.main.bundleIdentifier!

enum VoxDemoError: Int {
    case userPasswordRequired = 5019
    case outgoingCallCreationInternalVoximplant = 5030
    case outgoingCallCreationAlreadyManageCall = 5091
    
    private var description: String {
        switch self {
        case .outgoingCallCreationInternalVoximplant:
            return "Can't start an outgoing call: couldn't create a VICall instance."
        case .outgoingCallCreationAlreadyManageCall:
            return "Can't start an outgoing call: CallManager already has a manage call or nil."
        case .userPasswordRequired:
            return "User password is needed for login."
        }
    }
    
    var localizedDescriptionInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.description]
    }
}


extension VoxDemoError {
    static func errorRequiredPassword() -> NSError {
        return NSError(domain: AudioCallErrorDomain,
                       code: VoxDemoError.userPasswordRequired.rawValue,
                       userInfo: VoxDemoError.userPasswordRequired.localizedDescriptionInfo)
    }
    
    static func errorCouldntCreateCall() -> NSError {
        return NSError(domain: AudioCallErrorDomain,
                       code: VoxDemoError.outgoingCallCreationInternalVoximplant.rawValue,
                       userInfo: VoxDemoError.outgoingCallCreationInternalVoximplant.localizedDescriptionInfo)
    }
    
    static func errorAlreadyHasCall() -> NSError {
        return NSError(domain: AudioCallErrorDomain,
                       code: VoxDemoError.outgoingCallCreationAlreadyManageCall.rawValue,
                       userInfo: VoxDemoError.outgoingCallCreationAlreadyManageCall.localizedDescriptionInfo)
    }
}
