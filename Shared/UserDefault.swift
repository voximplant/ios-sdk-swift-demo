/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol UserDefaultsMain {
    static var main: UserDefaults { get }
}

extension UserDefaultsMain {
    static var main: UserDefaults {
        // Switching UserDefaults implementation needed for ScreenSharing and ScreenSharingUploadAppex targets.
        return UserDefaults.standard
    }
}

extension UserDefaults: UserDefaultsMain {}

fileprivate let userDefaults = UserDefaults.main
fileprivate let userDefaultsDomain = "" //Bundle.main.bundleIdentifier ?? ""
fileprivate extension String {
    var appendingAppDomain: String {
        "\(userDefaultsDomain).\(self)"
    }
}

@propertyWrapper
struct UserDefault<T> {
    let key: String
    
    init(_ key: String) {
        self.key = key.appendingAppDomain
    }
    
    var wrappedValue: T? {
        get { userDefaults.object(forKey: key) as? T }
        set { userDefaults.set(newValue, forKey: key) }
    }
}

@propertyWrapper
struct NonNilUserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key.appendingAppDomain
        self.defaultValue = defaultValue
        userDefaults.register(defaults: [key: defaultValue])
    }
    
    var wrappedValue: T {
        get { userDefaults.object(forKey: key) as? T ?? defaultValue }
        set { userDefaults.set(newValue, forKey: key) }
    }
}
