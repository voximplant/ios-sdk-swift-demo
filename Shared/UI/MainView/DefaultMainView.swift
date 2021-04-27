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
    
    private var callTouchHandler: ((String?) -> Void)?
    private var logoutTouchHandler: (() -> Void)?

    private var isConfigured = false
    
    // MARK: MovingWithKeyboard
    var adjusted: Bool = false
    var defaultPositionY: CGFloat = 0
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
