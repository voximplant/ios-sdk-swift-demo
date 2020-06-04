/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class DefaultCallFailedView:
    UIView,
    NibLoadable
{
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var reasonLabel: UILabel!
    
    var displayName: String? {
        get { displayNameLabel.text }
        set { displayNameLabel.text  = newValue }
    }
    var reason: String? {
        get { reasonLabel.text }
        set { reasonLabel.text = newValue }
    }
    var cancelHandler: (() -> Void)?
    var callBackHandler: (() -> Void)?
    
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
    }
    
    @IBAction private func cancelTouchUp(_ sender: PressableButton) {
        cancelHandler?()
    }
    
    @IBAction private func callBackTouchUp(_ sender: PressableButton) {
        callBackHandler?()
    }
}
