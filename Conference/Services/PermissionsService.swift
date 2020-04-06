/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import AVFoundation

final class PermissionsService {
    func requestPermissions(for mediaType: AVMediaType, completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized: completion(true)
        case .notDetermined: AVCaptureDevice.requestAccess(for: mediaType, completionHandler: completion)
        case .denied: completion(false)
        case .restricted: completion(false)
        @unknown default: completion(false)
        }
    }
}
