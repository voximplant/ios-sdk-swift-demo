//
//  Copyright (c) 2011-2026, Zingaya, Inc. All rights reserved.
//

import UIKit

extension UIApplication {
    var foregroundKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
