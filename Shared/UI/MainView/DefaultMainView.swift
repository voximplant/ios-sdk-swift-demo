/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class DefaultMainView:
    UIView,
    NibLoadable,
    VoximplantSDKVersionContainable,
    MovingWithKeyboard,
    UITextFieldDelegate
{
    @IBOutlet private weak var callToField: DefaultTextField!
    @IBOutlet private weak var loggedInLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var shareButton: LogSharingButton!
    
    @IBOutlet weak var callToFieldCenterY: NSLayoutConstraint!
    @IBOutlet weak var callToFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var callToField_CallButton_Spacing: NSLayoutConstraint!
    
    private var callToFieldCenterY_Inset: CGFloat = 0
    private let callButton_Keyboard_Spacing: CGFloat = 32
    
    private var callTouchHandler: ((String?) -> Void)?
    private var logoutTouchHandler: (() -> Void)?

    private var isConfigured = false
    
    // MARK: MovingWithKeyboard
    var adjusted: Bool = false
    var keyboardWillChangeFrameObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?

    func keyboardWillChange(heightOfKeyboard: CGFloat) {
        callToFieldCenterY_Inset = callToFieldCenterY.constant
        let bottomPoint: CGFloat = (callToFieldHeight.constant / 2) + callToField_CallButton_Spacing.constant + callToFieldHeight.constant
        let topOfKeyboard = (UIScreen.main.bounds.height / 2) - heightOfKeyboard
        if bottomPoint + callToFieldCenterY_Inset > topOfKeyboard - callButton_Keyboard_Spacing {
            callToFieldCenterY.constant = topOfKeyboard - bottomPoint - callButton_Keyboard_Spacing
        }
    }
    
    func keyboardWillHide() {
        callToFieldCenterY.constant = callToFieldCenterY_Inset
    }
    
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
        subscribeOnKeyboardEvents()
        callToField.delegate = self
        versionLabel.text = SDKVersion
    }
    
    deinit {
        unsubscribeFromKeyboardEvents()
    }

    func configure(displayName: String,
                   controller: UIViewController,
                   callHandler: @escaping (String?) -> Void,
                   logoutHandler: @escaping () -> Void
    ) {
        if isConfigured { return }
        loggedInLabel.text = displayName
        shareButton.presentingController = controller
        callTouchHandler = callHandler
        logoutTouchHandler = logoutHandler
        isConfigured = true
    }
    
    @IBAction private func callTouchUp(_ sender: ColoredButton) {
        callToField.resignFirstResponder()
        callTouchHandler?(callToField.text)
    }
    
    @IBAction private func logoutTouchUp(_ sender: UIButton) {
        callToField.resignFirstResponder()
        logoutTouchHandler?()
    }
    
    func setDisplayName(text: String) {
        loggedInLabel.text = text
    }
    
    // MARK: - UITextFieldDelegate -
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        callToField.resignFirstResponder()
        return true
    }
}
