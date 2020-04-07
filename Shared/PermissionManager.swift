/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import AVFoundation

class PermissionsManager {
    
    class func checkAudioPermisson(completionIfGranted completion: @escaping () -> Void) {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            AVAudioSession.sharedInstance().requestRecordPermission
            { granted in
                if granted {
                    DispatchQueue.main.async {
                        completion()
                    }
                } else {
                    let action = UIAlertAction(title: "Settings", style: .default)
                    { action in
                        let settings = URL(string: UIApplication.openSettingsURLString)!
                        if #available(iOS 10.0, *) { UIApplication.shared.open(settings) }
                        else { UIApplication.shared.openURL(settings) }
                    }
                    AlertHelper.showError(message: "Audio permissions required", action: action)
                }
            }
            return
        }
        DispatchQueue.main.async {
            completion()
        }
    }
    
}


