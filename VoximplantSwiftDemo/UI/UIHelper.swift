/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import UserNotifications
import AVFoundation
import Dispatch

class UIHelper {
    class func ShowError(error: String!, action: UIAlertAction? = nil) {
        if let rootViewController = AppDelegate.instance().window?.rootViewController {
            let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))

            if let alertAction = action {
                alert.addAction(alertAction)
            }

            DispatchQueue.main.async { () -> Void in
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }

    class func ShowIncomingCallAlert(for uuid: UUID!) {
        if let rootViewController = AppDelegate.instance().window?.rootViewController, let callManager = AppDelegate.instance().voxImplant!.callManager, let descriptor = callManager.call(uuid: uuid) {
            var player: AVAudioPlayer?
            do {
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: String(format: "%@/ringtone.aiff", Bundle.main.resourcePath!)))
                player!.numberOfLoops = -1
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
                player!.play()
            } catch {
                Log.e("\(error.localizedDescription)")
            }

            let alertController = UIAlertController(title: "Voximplant", message: String(format: "Incoming %@ call from %@", descriptor.withVideo ? "video" : "audio", descriptor.call!.endpoints!.first!.userDisplayName), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Reject", style: .destructive) { action in
                UIHelper.stopPlayer(player)
                AppDelegate.instance().voxImplant!.rejectCall(call: descriptor, mode: .decline)
            })
            alertController.addAction(UIAlertAction(title: descriptor.withVideo ? "Audio" : "Answer", style: .default) { action in
                UIHelper.stopPlayer(player)
                descriptor.withVideo = false
                AppDelegate.instance().voxImplant!.startCall(call: descriptor)
            })

            if (descriptor.withVideo) {
                alertController.addAction(UIAlertAction(title: "Video", style: .default) { action in
                    UIHelper.stopPlayer(player)
                    AppDelegate.instance().voxImplant!.startCall(call: descriptor)
                })
            }

            DispatchQueue.main.async { () -> Void in
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }

    class func ShowCallScreen() {
        if let rootViewController = AppDelegate.instance().window?.rootViewController {
            rootViewController.performSegue(withIdentifier: "CallController", sender: nil)
        }
    }

    fileprivate class func stopPlayer(_ player: AVAudioPlayer!) {
        player.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            Log.e("\(error.localizedDescription)")
        }
    }
}
