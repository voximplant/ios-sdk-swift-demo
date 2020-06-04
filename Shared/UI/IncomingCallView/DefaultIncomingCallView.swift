/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class DefaultIncomingCallView:
    UIView,
    NibLoadable
{
    @IBOutlet private weak var displayNameLabel: UILabel!
    
    var displayName: String? {
        get { displayNameLabel.text }
        set { displayNameLabel.text  = newValue }
    }
    var declineHandler: (() -> Void)?
    var acceptHandler: (() -> Void)?
    
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
    
    @IBAction private func declineTouchUp(_ sender: PressableButton) {
        declineHandler?()
    }
    
    @IBAction private func acceptTouchUp(_ sender: PressableButton) {
        acceptHandler?()
    }
}
