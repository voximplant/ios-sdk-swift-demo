/*
*  Copyright (c) 2011-2021, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CallReconnectDelegate: AnyObject {
    func callDidStartReconnecting(uuid: UUID)
    func callDidReconnect(uuid: UUID)
}
