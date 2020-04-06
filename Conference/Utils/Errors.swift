/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum Errors: Error {
    case unsupportedName
    case failedToBuildURL
    case noDataReceived
    case noActiveConferenceFound
    case audioPermissionsDenied
    case videoPermissionsDenied
}
