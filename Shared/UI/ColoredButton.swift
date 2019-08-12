/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

class ColoredButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func sharedInit() {
        layer.borderColor = #colorLiteral(red: 0.4, green: 0.1803921569, blue: 1, alpha: 1)
        self.setBackgroundImage(UIHelper.getImageWithColor(color: #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)), for: .highlighted)
        self.setBackgroundImage(UIHelper.getImageWithColor(color: #colorLiteral(red: 0.4, green: 0.1803921569, blue: 1, alpha: 1)), for: .normal)
    }
}
