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
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    UIHelper.ShowError(error: "Audio permissions required", action: action)
                }
            }
            return
        }
        DispatchQueue.main.async {
            completion()
        }
    }
    
}


