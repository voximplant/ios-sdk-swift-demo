/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

fileprivate let client = VIClient(delegateQueue: DispatchQueue.main)
fileprivate let authService: AuthService = VoximplantAuthService(client: client)
fileprivate let conferenceService: ConferenceService = VoximplantConferenceService(client: client)
fileprivate let apiService = VoximplantAPIService()
fileprivate let storyAssembler = StoryAssembler(authService, conferenceService, apiService)

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, Loggable {
    var window: UIWindow?
    var appName: String { "Conference" }
    
    override init() {
        super.init()
        configureDefaultLogging()
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = storyAssembler.login
        window?.makeKeyAndVisible()
        
        return true
    }
}
