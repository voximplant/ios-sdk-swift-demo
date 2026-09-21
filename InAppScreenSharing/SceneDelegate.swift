/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    private var appDelegate: AppDelegate? { UIApplication.shared.delegate as? AppDelegate }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene, let appDelegate = appDelegate else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = appDelegate.storyAssembler.login
        window.makeKeyAndVisible()
        self.window = window
    }
    
    // MARK: - AppLifeCycleDelegate -
    func sceneWillResignActive(_ scene: UIScene) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationWillResignActive(.shared)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationDidEnterBackground(.shared)
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationWillEnterForeground(.shared)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        (window?.rootViewController?.toppestViewController as? AppLifeCycleDelegate)?.applicationDidBecomeActive(.shared)
    }
}
