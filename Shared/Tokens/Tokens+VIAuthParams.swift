/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

extension Tokens {
    static func update(with authParams: VIAuthParams) {
        access = Token(
            token: authParams.accessToken,
            expireDate: Date(timeIntervalSinceNow: authParams.accessExpire)
        )
        refresh = Token(
            token: authParams.refreshToken,
            expireDate: Date(timeIntervalSinceNow: authParams.refreshExpire)
        )
    }
}
