/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, Loggable {
    var window: UIWindow?
    var appName: String { "Conference" }
    
    override init() {
        super.init()
        
        configureDefaultLogging()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = StoryAssembler.assembleLogin()
        window?.makeKeyAndVisible()
        
        return true
    }
}
