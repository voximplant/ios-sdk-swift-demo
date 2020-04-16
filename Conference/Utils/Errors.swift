/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum Errors: Error {
    case unsupportedName
    case failedToBuildURL
    case noDataReceived
    case jsonDecodingFailed
    case noActiveConferenceFound
    case audioPermissionsDenied
    case videoPermissionsDenied
    
    var localizedDescription: String {
        switch self {
        case .unsupportedName:
            return "Given name is not supported by the system"
        case .failedToBuildURL:
            return "Could not start the conference. Please try again"
        case .noDataReceived:
            return "Could not start the conference. Please try again"
        case .jsonDecodingFailed:
            return "Could not start the conference. Please try again"
        case .noActiveConferenceFound:
            return "Active conference does not exist"
        case .audioPermissionsDenied:
            return "Audio permissions denied"
        case .videoPermissionsDenied:
            return "Video permissions denied"
        }
    }
}
