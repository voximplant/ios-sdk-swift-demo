/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum LoginViewState {
    case normal
    case loading
}

final class LoginView: UIView, UITextFieldDelegate {
    @IBOutlet private weak var fieldsContainerView: UIView!
    @IBOutlet private weak var joinWithVideoButton: UIButton!
    @IBOutlet private weak var joinWithoutVideoButton: UIButton!
    @IBOutlet private weak var IDField: LoginTextField!
    @IBOutlet private weak var nameField: LoginTextField!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    var idText: String? {
        IDField.text != "" ? IDField.text : nil
    }
    
    var nameText: String? {
        nameField.text != "" ? nameField.text : nil
    }
    
    var state: LoginViewState = .normal {
        didSet {
            switch state {
            case .normal:
                if (activityIndicator.isAnimating) {
                    activityIndicator.stopAnimating()
                }
                execute {
                    self.activityIndicator.alpha = 0
                    self.fieldsContainerView.alpha = 1
                }
            case .loading:
                activityIndicator.startAnimating()
                execute {
                    self.activityIndicator.alpha = 1
                    self.fieldsContainerView.alpha = 0
                }
            }
        }
    }
    
    func setupView() {
        IDField.delegate = self
        nameField.delegate = self
        fieldsContainerView.layer.cornerRadius = 4
        
        joinWithVideoButton.layer.cornerRadius = 4
        joinWithoutVideoButton.layer.cornerRadius = 4
        // TODO: HIDES CALL WITHOUT VIDEO BUTTON
        joinWithoutVideoButton.isHidden = true
        joinWithoutVideoButton.frame = CGRect(x: joinWithoutVideoButton.frame.origin.x,
                                              y: joinWithoutVideoButton.frame.origin.y,
                                              width: joinWithoutVideoButton.frame.size.width,
                                              height: 0)
        // TODO: HIDES CALL WITHOUT VIDEO BUTTON END
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func showLatestUsername(_ name: String) {
        nameField.text = name
    }
    
    func hideKeyboard() {
        if IDField.isFirstResponder {
            IDField.resignFirstResponder()
        } else if nameField.isFirstResponder {
            nameField.resignFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Private -
    private func execute(animation: @escaping () -> Void) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: animation, completion: nil)
        }
    }
    
    @objc private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue

        if notification.name == UIResponder.keyboardWillHideNotification {
            frame.origin.y = 0
        } else {
            if frame.origin.y == 0 {
                if #available(iOS 11.0, *) {
                    frame.origin.y -= (keyboardScreenEndFrame.height - safeAreaInsets.bottom) / 2
                } else {
                    frame.origin.y -= (keyboardScreenEndFrame.height) / 2
                }
            }
        }
    }
    
    // MARK: - UITextFieldDelegate -
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == IDField {
            nameField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
}
