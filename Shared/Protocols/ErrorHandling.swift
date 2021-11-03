/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ErrorHandling where Self: UIViewController { }

extension ErrorHandling {
    func handleError(_ error: Error) {
        if case PermissionError.audioPermissionDenied = error {
            AlertHelper.showErrorWithSettingsAction(message: "Audio permissions needed", on: self)
        } else if case PermissionError.videoPermissionDenied = error {
            AlertHelper.showErrorWithSettingsAction(message: "Video permissions needed", on: self)
        } else {
            AlertHelper.showError(message: error.localizedDescription, on: self)
        }
    }
    
    func showErrorAlert(title: String, message: String) {
        AlertHelper.showAlert(title: title,
                              message: message,
                              actions: [UIAlertAction(title: "Ok", style: .cancel)],
                              defaultAction: false,
                              on: self)
    }
}
