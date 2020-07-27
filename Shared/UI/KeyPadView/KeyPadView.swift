/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class KeyPadView: UIView, NibLoadable {
    @IBOutlet private var numberButtons: [PressableButton]!
    
    var hideHandler: (() -> Void)?
    var DTMFHandler: ((String) -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    private func sharedInit() {
        setupFromNib()
    }
    
    @IBAction private func numberTouch(_ sender: PressableButton) {
        if let symbolSentFromDTMF = sender.currentTitle {
            DTMFHandler?(symbolSentFromDTMF)
        }
    }
    
    @IBAction private func hideTouch(_ sender: PressableButton) {
        hideHandler?()
    }
}
