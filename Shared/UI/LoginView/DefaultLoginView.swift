/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class DefaultLoginView:
    UIView,
    NibLoadable,
    UITextFieldDelegate,
    MovingWithKeyboard
{
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var usernameField: DefaultTextField!
    @IBOutlet private weak var passwordField: DefaultTextField!
    
    var username: String? {
        get { usernameField.text }
        set { usernameField.text = newValue }
    }
    var password: String? {
        get { passwordField.text }
        set { passwordField.text = newValue }
    }
    
    var loginTouchHandler: ((String, String) -> Void)?
    
    // MARK: MovingWithKeyboard
    var adjusted: Bool = false
    var defaultPositionY: CGFloat = 0.0
    var keyboardWillChangeFrameObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    private func sharedInit() {
        setupFromNib()
        usernameField.delegate = self
        passwordField.delegate = self
        subscribeOnKeyboardEvents()
        usernameField.padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 122)
    }
    
    deinit {
        unsubscribeFromKeyboardEvents()
    }
    
    @IBAction private func loginTouchUp(_ sender: ColoredButton) {
        hideKeyboard()
        loginTouchHandler?(username ?? "", password ?? "")
    }
    
    private func hideKeyboard() {
        if usernameField.isFirstResponder {
            usernameField.resignFirstResponder()
        } else if passwordField.isFirstResponder {
            passwordField.resignFirstResponder()
        }
    }
    
    func setTitle(text: String) {
        titleLabel.text = text
    }
    
    // MARK: - UITextFieldDelegate -
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            passwordField.resignFirstResponder()
        }
        
        return true
    }
}
