/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import Foundation

enum PermissionError: Error {
    case audioPermissionDenied
    case videoPermissionDenied
    
    var localizedDescription: String {
        switch self {
        case .audioPermissionDenied:
           return "Record audio permission needed for call to work"
        case .videoPermissionDenied:
           return "Record video permission needed for video call to work"
        }
    }
}

enum AuthError: Error {
    case loginDataNotFound
    case notLoggedIn
    
    var localizedDescription: String {
        switch self {
        case .loginDataNotFound:
            return "Login data was not found, try to login with password"
        case .notLoggedIn:
            return "User is not logged in"
        }
    }
}

enum CallError: Error {
    case internalError
    case alreadyManagingACall
    case hasNoActiveCall
    
    var localizedDescription: String {
        switch self {
        case .internalError:
           return "There was an internal error starting the call. Try again"
        case .alreadyManagingACall:
           return "The app already managing a call, only a single call at a time allowed"
        case .hasNoActiveCall:
            return "Active call not found, action cancelled"
        }
    }
}
