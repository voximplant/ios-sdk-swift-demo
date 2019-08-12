//
//  Application.swift
//  Voximplant Demo
//
//  Created by Andrey Efremov on 05/08/2019.
//  Copyright © 2019 Zingaya Ltd. All rights reserved.
//

import UIKit

// MARK: UIApplication's domain constants
extension UIApplication {
    class var errorDomain: String {
        return Bundle.main.bundleIdentifier!
    }
}

extension UIApplication {
    class var userDefaultsDomain: String {
        return Bundle.main.bundleIdentifier!
    }
}

// MARK: AppLifeCycleDelegate declaration
protocol AppLifeCycleDelegate {
    func applicationWillResignActive(_ application: UIApplication)
    func applicationDidEnterBackground(_ application: UIApplication)
    func applicationWillEnterForeground(_ application: UIApplication)
    func applicationDidBecomeActive(_ application: UIApplication)
}

extension AppLifeCycleDelegate {
    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
}

