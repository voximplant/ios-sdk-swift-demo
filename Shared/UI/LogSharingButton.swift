/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LogSharingButton: UIButton, LogSharingView {
    weak var presentingController: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    private func sharedInit() {
        addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
    }

    @objc private func touchUpInside(_ sender: LogSharingButton) {
        if let controller = presentingController {
            showSharingScreen(on: controller)
        }
    }
}
