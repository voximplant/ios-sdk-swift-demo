/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation

fileprivate extension UserDefaults {
    private var tokenIDMainKey: String {
        return "com.voximplant.demos.swift.token.content"
    }
    
    private var expiredDateMainKey: String {
        return "com.voximplant.demos.swift.token.expiredate"
    }
    
    func tokenIDKey(for user: String) -> String {
        return tokenIDMainKey + "." + user
    }
    
    func expiredDateKey(for user: String) -> String {
        return expiredDateMainKey + "." + user
    }
}

protocol Key {
    var user: String { get }
    var token: String { get }
    var expire: Date { get }
}

class PersistentKey: Key {
    // We strongly recommend to use keychain to store tokens persistently. In this sample we will use UserDefaults for this need.
    fileprivate let userDefaults = UserDefaults.standard
    
    private(set) var user: String
    private(set) var token: String {
        set {
            userDefaults.set(newValue, forKey: userDefaults.tokenIDKey(for: String(describing: type(of: self)) + "." + user))
            userDefaults.synchronize()
        }
        get {
            return userDefaults.object(forKey: userDefaults.tokenIDKey(for: String(describing: type(of: self)) + "." + user)) as! String
        }
    }
    
    private(set) var expire: Date {
        set {
            userDefaults.set(newValue, forKey: userDefaults.expiredDateKey(for: String(describing: type(of: self)) + "." + user))
            userDefaults.synchronize()
        }
        get {
            return userDefaults.object(forKey: userDefaults.expiredDateKey(for: String(describing: type(of: self)) + "." + user)) as! Date
        }
    }
    
    init(user: String, token: String, expire: Date) {
        self.user = user
        self.token = token
        self.expire = expire
    }
    
    init?(user: String) {
        if let _ = userDefaults.object(forKey: userDefaults.tokenIDKey(for: String(describing: type(of: self)) + "." + user)) as? String,
            let _ = userDefaults.object(forKey: userDefaults.expiredDateKey(for: String(describing: type(of: self)) + "." + user)) as? Date
        {
            self.user = user
        } else {
            return nil
        }
    }
}

struct MemoryKey: Key {
    private(set) var user: String
    private(set) var token: String
    private(set) var expire: Date
}

class AccessKey: PersistentKey {}
class RefreshKey: PersistentKey {}
