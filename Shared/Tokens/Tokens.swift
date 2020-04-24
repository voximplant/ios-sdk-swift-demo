/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import Foundation

fileprivate let tokenHolderKey = "keyholder"

enum Tokens {
    static var access: Token? {
        get {
            if let token = accessToken,
                let date = accessTokenExpireDate {
                return Token(token: token, expireDate: date)
            }
            return nil
        }
        set {
            accessToken = newValue?.token
            accessTokenExpireDate = newValue?.expireDate
        }
    }
    
    static var areExist: Bool {
        access != nil && refresh != nil
    }
    
    static var areExpired: Bool {
        guard let access = access,
            let refresh = refresh else { return true }
        
        return access.isExpired || refresh.isExpired
    }
    
    @UserDefault("\(tokenHolderKey)/token/access")
    private static var accessToken: String?
    
    @UserDefault("\(tokenHolderKey)/date/access")
    private static var accessTokenExpireDate: Date?
    
    static var refresh: Token? {
        get {
            if let token = refreshToken,
                let date = refreshTokenExprireDate {
                return Token(token: token, expireDate: date)
            }
            return nil
        }
        set {
            refreshToken = newValue?.token
            refreshTokenExprireDate = newValue?.expireDate
        }
    }
    
    @UserDefault("\(tokenHolderKey)/token/refresh")
    private static var refreshToken: String?
    
    @UserDefault("\(tokenHolderKey)/date/refresh")
    private static var refreshTokenExprireDate: Date?
    
    static func clear() {
        access = nil
        refresh = nil
    }
}

struct Token {
    let token: String
    let expireDate: Date
    var isExpired: Bool { Date() > expireDate }
}

