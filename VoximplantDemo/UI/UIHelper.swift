/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import UserNotifications
import AVFoundation
import Dispatch

class UIHelper {
    fileprivate static var incomingCallAlert: UIAlertController?
    fileprivate static var player: AVAudioPlayer?

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
    

    class func ShowIncomingCallAlert(for uuid: UUID!, completion: @escaping ()-> Void) {
        if let rootViewController = AppDelegate.instance().window?.rootViewController, let callManager = AppDelegate.instance().voxImplant!.callManager, let descriptor = callManager.call(uuid: uuid) {
            var userName = "";
            if let userDisplayName = descriptor.call?.endpoints.first?.userDisplayName {
                userName = " from \(userDisplayName)"
            }
            let incomingCallAlert: UIAlertController = UIAlertController(title: "Voximplant", message: String(format: "Incoming %@ call%@", descriptor.withVideo ? "video" : "audio", userName), preferredStyle: .alert)
            self.incomingCallAlert = incomingCallAlert
            incomingCallAlert.addAction(UIAlertAction(title: "Reject", style: .destructive) { action in
                completion()
                AppDelegate.instance().voxImplant!.rejectCall(call: descriptor, mode: .decline)
            })
            incomingCallAlert.addAction(UIAlertAction(title: descriptor.withVideo ? "Audio" : "Answer", style: .default) { action in
                completion()
                descriptor.withVideo = false
                AppDelegate.instance().voxImplant!.startCall(call: descriptor)
            })

            if (descriptor.withVideo) {
                incomingCallAlert.addAction(UIAlertAction(title: "Video", style: .default) { action in
                    completion()
                    AppDelegate.instance().voxImplant!.startCall(call: descriptor)
                })
            }

            DispatchQueue.main.async { () -> Void in
                rootViewController.present(incomingCallAlert, animated: true, completion: nil)
            }
        }
    }

    class func DismissIncomingCallAlert(completion: @escaping ()-> Void) {
        if let _ = incomingCallAlert, let rootViewController = AppDelegate.instance().window?.rootViewController {
            rootViewController.dismiss(animated: true) {
                completion()
            }
            incomingCallAlert = nil
        }
    }

    class func ShowCallScreen() {
        if let rootViewController = AppDelegate.instance().window?.rootViewController {
            rootViewController.performSegue(withIdentifier: "CallController", sender: nil)
        }
    }

}

//MARK: - Playing call ringtone

extension UIHelper {
    
    /**
     `StartPlayingRingtone` creates `AVAudioPlayer`
     for playing a custom ringtone when the app is in the foreground.
     
     To stop playing ringtone when the app is in the foreground
     you should use `StopPlayingRingtone`
     
     For playing a custom ringtone when the app is in the background
     you should use `UNMutableNotificationContent()`:
     
     ```
     ...
     let content = UNMutableNotificationContent()
     ...
     content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "ringtone.aiff"))
     ...
     ```
     */
    
    class func StartPlayingRingtone() {
        do {
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: String(format: "%@/ringtone.aiff", Bundle.main.resourcePath!)))
            player?.numberOfLoops = -1
            let audioSession = AVAudioSession.sharedInstance()
            if #available(iOS 10.0, *) {
                try audioSession.setCategory(AVAudioSession.Category.ambient, mode: .default)
            } else {
                // Workaround until https://forums.swift.org/t/using-methods-marked-unavailable-in-swift-4-2/14949 is fixed
                audioSession.perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.ambient)
            }
            try audioSession.setActive(true)
            player?.prepareToPlay()
            player?.play()
        } catch {
            Log.e("\(error.localizedDescription)")
        }
    }
    
    /**
     Opposite to `StartPlayingRingtone`
     */
    
    class func StopPlayingRingtone() {
        guard let player = player else { return }
        player.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            Log.e("\(error.localizedDescription)")
        }
    }

}
