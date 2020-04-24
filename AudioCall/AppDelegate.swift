/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

let sharedClient: VIClient = VIClient(delegateQueue: DispatchQueue.main)
let sharedAuthService: AuthService = AuthService(sharedClient)
let sharedCallManager: CallManager = CallManager(sharedClient, sharedAuthService)

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, CallManagerDelegate {
    
    var window: UIWindow?
    var callManager: CallManager = sharedCallManager
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Log.enable(level: .debug)
        VIClient.setLogLevel(.info)
        
        callManager.delegate = self
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Log.i("AudioCall Swift Demo v\(version) started", context: self)
        }
        UIApplication.shared.isIdleTimerDisabled = true
        
        
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
    // MARK: - CallManagerDelegate -
    func notifyIncomingCall(_ call: VICall) {
        (window?.rootViewController?.toppestViewController as? CallManagerDelegate)?.notifyIncomingCall(call)
    }
}
