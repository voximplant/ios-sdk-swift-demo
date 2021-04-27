/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK

extension UserDefaults {
    static var main: UserDefaults {
        // App Group UserDefaults needed for communication between the app and the appex
        return UserDefaults(suiteName: "group.com.voximplant.demos")!
    }
}

fileprivate let client: VIClient = VIClient(delegateQueue: DispatchQueue.main)
fileprivate let authService: AuthService = AuthService(client)
fileprivate let darwinNotificationService = DarwinNotificationCenter()
fileprivate let callManager: CallManager = CallManager(client, authService, darwinNotificationService)
fileprivate let storyAssembler: StoryAssembler = StoryAssembler(authService: authService, callManager: callManager)

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    override init() {
        super.init()
        Logger.configure(appName: "ScreenSharing")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = storyAssembler.login
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: - AppLifeCycleDelegate -
    func applicationWillResignActive(_ application: UIApplication) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationWillResignActive(application)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationDidEnterBackground(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationWillEnterForeground(application)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationDidBecomeActive(application)
    }
}

