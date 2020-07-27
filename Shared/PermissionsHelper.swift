/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import AVFoundation

final class PermissionsHelper {
    static func requestRecordPermissions(
        includingVideo video: Bool = false,
        completion: @escaping (Error?) -> Void,
        accessRequestCompletionQueue: DispatchQueue = .main
    ) {
        requestPermissions(for: .audio, queue: accessRequestCompletionQueue) { granted in
            if granted {
                if video {
                    requestPermissions(for: .video, queue: accessRequestCompletionQueue) { granted in
                        completion(granted ? nil : PermissionError.videoPermissionDenied)
                    }
                    return
                }
                completion(nil)
            } else {
                completion(PermissionError.audioPermissionDenied)
            }
        }
    }
    
    static func requestPermissions(
        for mediaType: AVMediaType,
        queue: DispatchQueue = .main,
        completion: @escaping (Bool) -> Void
    ) {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                queue.async {
                    completion(granted)
                }
            }
        case .authorized: completion(true)
        case .denied:     completion(false)
        case .restricted: completion(false)
        @unknown default: completion(false)
        }
    }
}

