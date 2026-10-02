/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    let storyAssembler: StoryAssembler
    
    override init() {
        let client = VIClient(delegateQueue: DispatchQueue.main)
        let authService = AuthService(client)
        let callManager = CallManager(client, authService)
        self.storyAssembler = StoryAssembler(authService, callManager)
        super.init()
        Logger.configure(appName: "AudioCall")
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        return true
    }
}
