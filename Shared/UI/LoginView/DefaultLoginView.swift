/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class DefaultLoginView:
    UIView,
    NibLoadable,
    UITextFieldDelegate
{
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var usernameField: DefaultTextField!
    @IBOutlet private weak var passwordField: DefaultTextField!
    @IBOutlet private weak var shareButton: LogSharingButton!
    @IBOutlet private weak var nodePicker: DefaultPickerView!

    var username: String? {
        get { usernameField.text }
        set { usernameField.text = newValue }
    }
    var password: String? {
        get { passwordField.text }
        set { passwordField.text = newValue }
    }

    private var loginTouchHandler: ((String, String, String) -> Void)?

    private var isConfigured = false

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
        usernameField.padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 122)
    }

    func configure(title: String, controller: UIViewController, loginHandler: @escaping (String, String, String) -> Void) {
        if isConfigured { return }
        titleLabel.text = title
        shareButton.presentingController = controller
        loginTouchHandler = loginHandler
        isConfigured = true
        let nodes = ["Node 1",
                     "Node 2",
                     "Node 3",
                     "Node 4",
                     "Node 5",
                     "Node 6",
                     "Node 7",
                     "Node 8",
                     "Node 9",
                     "Node 10"]
        nodePicker.configure(with: nodes, defaultRow: 3)
    }

    @IBAction private func loginTouchUp(_ sender: ColoredButton) {
        hideKeyboard()
        loginTouchHandler?(username ?? "", password ?? "", nodePicker.selectedValue)
    }

    private func hideKeyboard() {
        if usernameField.isFirstResponder {
            usernameField.resignFirstResponder()
        } else if passwordField.isFirstResponder {
            passwordField.resignFirstResponder()
        }
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
