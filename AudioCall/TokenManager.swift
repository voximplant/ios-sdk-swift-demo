/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation

// Class that stores and provide access to login tokens: access and refresh.
// If requested token does not exist or expired, it returns nil.
class TokenManager {
    // Access and refresh tokens could be stored persistently. They differ by their expiration date.
    fileprivate var accessKey: AccessKey?
    fileprivate var refreshKey: RefreshKey?
    
    subscript(user: String) -> (access: AccessKey?, refresh: RefreshKey?) {
        get {
            if let accessKey = self.accessKey,
               let refreshKey = self.refreshKey,
               accessKey.user == user,
               Date() < accessKey.expire
            {
                return (accessKey, refreshKey)
            } else if let accessKey = AccessKey(user: user),
                      let refreshKey = RefreshKey(user: user),
                      Date() < accessKey.expire
            {
                return (accessKey, refreshKey)
            } else if let refreshKey = RefreshKey(user: user),
                      Date() < refreshKey.expire
            {
                return (nil, refreshKey)
            } else {
                // If TokenManager instance don't have access token and refresh token or this tokens are expired.
                return (nil, nil)
            }
        }
        set (newValue) {
            if let accessKey = newValue.access,
               let refreshKey = newValue.refresh
            {
                self.accessKey = accessKey
                self.refreshKey = refreshKey
            } else {
                abort() // use tokensManager[user] = (nonnil_access_token, nonnil_refresh_token)
            }
        }
    }
}
