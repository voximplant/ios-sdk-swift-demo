/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol LogSharingView: UIView {
    func showSharingScreen(on: UIViewController)
}

extension LogSharingView {
    var logURL: URL? {
        Logger.logFilePath
    }

    func showSharingScreen(on controller: UIViewController) {
        guard let logURL = logURL else {
            AlertHelper.showAlert(title: "Sharing failed", message: "Could'nt locate log file", on: controller)
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [logURL],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.sourceView = self

        controller.present(activityViewController, animated: true, completion: nil)
    }
}
