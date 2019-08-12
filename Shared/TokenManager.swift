/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

typealias Keys = (access: Token, refresh: Token)
fileprivate let userDefaults = UserDefaults.standard

fileprivate extension UserDefaults {
    var keyholderKey: String {
        return UIApplication.userDefaultsDomain + "." + "keyholder"
    }
}

fileprivate extension UserDefaults {
    func token(forKey key: String) -> Token? {
        guard let token = string(forKey: userDefaults.keyholderKey + "/token" + key),
              let date = object(forKey: userDefaults.keyholderKey + "/date" + key) as? Date
        else { return nil }
        
        return Token(token: token, expireDate: date)
    }
    
    func setToken(_ token: Token?, forKey key: String) {
        set(token?.token, forKey: userDefaults.keyholderKey + "/token" + key)
        set(token?.expireDate, forKey: userDefaults.keyholderKey + "/date" + key)
    }
}

class TokenManager {
    var keys: Keys? {
        get {
            guard let accessKey = userDefaults.token(forKey: "access"),
                  let refreshKey = userDefaults.token(forKey: "refresh")
            else { return nil }
            return (accessKey, refreshKey)
        }
        set {
            userDefaults.setToken(newValue?.access, forKey: "access")
            userDefaults.setToken(newValue?.refresh, forKey: "refresh")
        }
    }
}

class Token {
    private(set) var token: String
    private(set) var expireDate: Date
    var isExpired: Bool { return Date() > expireDate }
    
    init(token: String, expireDate: Date) {
        self.token = token
        self.expireDate = expireDate
    }
}
