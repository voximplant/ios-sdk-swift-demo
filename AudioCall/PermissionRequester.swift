/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import AVFoundation
import UIKit

protocol PermissionNeeded {
    func permissionNeeded()
}

extension AVCaptureDevice {
    class func requestPermissionIfNeeded(for type: AVMediaType) {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: type)
            { granted in
                // nothing
            }
        case .restricted, .denied:
            let action = UIAlertAction(title: "Settings", style: .default)
            { action in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            }
            UIHelper.ShowError(error: "\(type.rawValue) permissions required", action: action)
            
        case .authorized:
            fallthrough
        default:
            break
        }
    }
}
