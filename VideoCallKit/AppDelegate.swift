/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK
import CallKit
import Intents

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, CXCallObserverDelegate {
    let storyAssembler: StoryAssembler
    
    private let callController: CXCallController
    private let callManager: CallManager
    private var sceneWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0.delegate as? SceneDelegate)?.window }
            .first
    }
    
    override init() {
        let client = VIClient(delegateQueue: DispatchQueue.main, bundleId: Bundle.main.bundleIdentifier)
        let authService = AuthService(client)
        let callController = CXCallController(queue: .main)
        let callManager = CallManager(client, authService)
        self.callController = callController
        self.callManager = callManager
        self.storyAssembler = StoryAssembler(authService, callManager, callController)
        super.init()

        Logger.configure(appName: "VideoCallKit")
        callController.callObserver.setDelegate(self, queue: .main)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }
    
    func startCall(from userActivity: NSUserActivity) {
        if callManager.hasManagedCall { return }
        guard let startCallIntent = userActivity.interaction?.intent,
              let username = (startCallIntent as? INStartCallIntent)?.contacts?.first?.personHandle?.value
        else { return }
        let startOutgoingCall = CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: username))
        
        callController.requestTransaction(with: startOutgoingCall) { error in
            guard let error = error else { return }
            AlertHelper.showError(message: error.localizedDescription)
            Log.e(error.localizedDescription)
        }
    }
    
    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        (sceneWindow?.rootViewController?.toppestViewController as? CXCallObserverDelegate)?
            .callObserver(callObserver, callChanged: call)
    }
}
