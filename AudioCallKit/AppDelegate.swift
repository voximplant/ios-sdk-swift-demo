/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK
import CallKit
import Intents

let sharedClient: VIClient = VIClient(delegateQueue: DispatchQueue.main)
let sharedAuthService: AuthService = AuthService(sharedClient)
let sharedCallController: CXCallController = CXCallController(queue: .main)
let sharedCallManager: CallManager = CallManager(sharedClient, sharedAuthService)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CXCallObserverDelegate {
    var window: UIWindow?
    var callManager = sharedCallManager
    var callController = sharedCallController
    
    override init() {
        super.init()
        Logger.configure(appName: "AudioCallKit")
        callController.callObserver.setDelegate(self, queue: .main)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if callManager.hasManagedCall { return false }
        guard let startCallIntent = userActivity.interaction?.intent else { return false }
        var username: String?
        
        if #available(iOS 13.0, *) { username = (startCallIntent as? INStartCallIntent)?.contacts?.first?.personHandle?.value }
        else { username = (startCallIntent as? INStartAudioCallIntent)?.contacts?.first?.personHandle?.value }
        
        guard username != nil else { return false }
        let startOutgoingCall = CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: username!))
        
        self.callController.requestTransaction(with: startOutgoingCall) { error in
            guard let error = error else { return }
            AlertHelper.showError(message: error.localizedDescription)
            Log.e(error.localizedDescription)
        }
        return true
    }
    
    // MARK: - AppLifeCycle -
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
    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        (window?.rootViewController?.toppestViewController as? CXCallObserverDelegate)?.callObserver(callObserver, callChanged: call)
    }
}
