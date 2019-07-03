/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CocoaLumberjack

let sharedClient: VIClient = VIClient(delegateQueue: DispatchQueue.main)
let sharedAuthService: AuthService = AuthService(sharedClient)
let sharedCallManager: CallManager = {
    let callManager = CallManager(sharedClient, sharedAuthService)
    return callManager
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Log.enable(level: .debug)
        VIClient.setLogLevel(.info)
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Log.i("Voximplant Swift Demo v\(version) started", context: self)
        }
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if let navigationController = window?.rootViewController as? UINavigationController,
            let controllerWithReconnect = navigationController.topViewController as? MainViewController {
            if controllerWithReconnect.presentedViewController == nil {
                controllerWithReconnect.reconnect() //reconnect if on the mainviewcontroller only
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
