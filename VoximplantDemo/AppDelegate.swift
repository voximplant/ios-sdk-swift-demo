/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK
import CocoaLumberjack
import UserNotifications
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var voxImplant: VoxController?

    var callKit: Bool! {
        didSet {
            if oldValue != callKit {
                self.voxImplant?.changeCallManager()
            }
        }
    }
    var cameraMode: CameraMode!
    var preferredCodec: VIVideoCodec!

    static func instance() -> AppDelegate! {
        if (!Thread.isMainThread) {
            var instance: AppDelegate!
            DispatchQueue.main.sync {
                instance = AppDelegate.instance();
            }
            return instance
        }
        return UIApplication.shared.delegate as? AppDelegate;
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Log.enable(level: .debug)

        Theme.applyTheme()

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Log.i("Voximplant Swift Demo v\(version) started", context: self)
        }

        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
        }

        UIApplication.shared.isIdleTimerDisabled = true

        self.callKit = Settings.shared.callKitEnabled

        var orientation = VISupportedDeviceOrientation(rawValue: Settings.shared.supportedOrientation)
        if (orientation.rawValue == 0) {
            orientation = .all
        }
        VICameraManager.shared().setSupportedDeviceOrientation(iPhone: orientation, iPad: orientation)
        VICameraManager.shared().useBackCamera = Settings.shared.defaultToBackCamera
        VICameraManager.shared().shouldMirrorFrontCamera = Settings.shared.cameraMirroring

        self.cameraMode = Settings.shared.cameraMode

        self.preferredCodec = Settings.shared.preferredCodec

        self.voxImplant = VoxController()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        UIApplication.shared.isIdleTimerDisabled = false
        UserDefaults.standard.synchronize()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if let descriptor = self.voxImplant?.callManager?.pendingCall {
            UIHelper.StartPlayingRingtone()
            UIHelper.ShowIncomingCallAlert(for: descriptor.uuid) {
                UIHelper.StopPlayingRingtone()
            }
        } else if let window = self.window, let navigationController = window.rootViewController as? UINavigationController, navigationController.viewControllers.count > 1 {
            for vc in navigationController.viewControllers {
                if let mainViewController = vc as? MainViewController {
                    navigationController.popToViewController(vc, animated: false)
                    mainViewController.reconnect()
                }
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.voxImplant!.remoteNotificationsCallback(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.voxImplant!.remoteNotificationsCallback(error)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.voxImplant!.didReceiveRemoteNotification(payload: userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        switch userActivity.activityType {
        case "INStartVideoCallIntent":
            Log.d("Ask for video Intent")
            if let call = self.voxImplant?.callManager?.activeCall?.call {
                call.startReceiveVideo { error in
                    guard error == nil else {
                        UIHelper.ShowError(error: error?.localizedDescription, action: nil)
                        return
                    }
                    call.setSendVideo(true) { error in
                        if let error = error {
                            UIHelper.ShowError(error: error.localizedDescription, action: nil)
                        }
                    }
                }
            }
            return true
        case "INStartAudioCallIntent":
            Log.d("Ask for audio Intent")
            return true
        default:
            return false
        }
    }
}

@available(iOS 8.0, *)
extension AppDelegate {
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        self.voxImplant?.registerForPushNotifications()
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if (UIApplication.shared.applicationState == .active) {
            if let content = notification.userInfo {
                UIHelper.StartPlayingRingtone()
                UIHelper.ShowIncomingCallAlert(for: UUID(uuidString: content["uuid"] as! String)) {
                    UIHelper.StopPlayingRingtone()
                }
            }
        }
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        if let content = notification.userInfo,
           let uuid = UUID(uuidString: content["uuid"] as! String),
           let action = CallNotificationAction(rawValue: identifier!),
           let descriptor = self.voxImplant?.callManager?.call(uuid: uuid) {
            processCall(action, forCall: descriptor)
        }
    }

    func processCall(_ action: CallNotificationAction!, forCall descriptor: CallDescriptor!) {
        if let vox = self.voxImplant {
            switch action {
            case .reject?:
                vox.rejectCall(call: descriptor, mode: .decline)
            case .answerAudio?:
                descriptor.withVideo = false
                fallthrough
            case .answerVideo?:
                vox.startCall(call: descriptor)
            default:
                break
            }
        }
    }
}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if (UIApplication.shared.applicationState == .active) {
            let content = notification.request.content.userInfo as [AnyHashable: Any]
            UIHelper.StartPlayingRingtone()
            UIHelper.ShowIncomingCallAlert(for: UUID(uuidString: content["uuid"] as! String)) {
                UIHelper.StopPlayingRingtone()
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let uuid = UUID(uuidString: response.notification.request.content.userInfo["uuid"] as! String),
           let action = CallNotificationAction(rawValue: response.actionIdentifier),
           let descriptor = self.voxImplant?.callManager?.call(uuid: uuid) {
            processCall(action, forCall: descriptor)
        }
    }
}

