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

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    let storyAssembler: StoryAssembler
    
    override init() {
        let client = VIClient(delegateQueue: DispatchQueue.main)
        let authService = AuthService(client)
        let callManager = CallManager(client, authService, DarwinNotificationCenter())
        self.storyAssembler = StoryAssembler(authService: authService, callManager: callManager)
        super.init()
        Logger.configure(appName: "ScreenSharing")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }
}
