/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

class CustomTextField: UITextField { // this class used to work with textfiled and reuse it
    
    @IBOutlet override var rightView: UIView? {
        get {
            return super.rightView
        }
        set {
            super.rightView = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        layer.shadowRadius = 15
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.03
        rightViewMode = .always
    }

    
    @IBAction func nextField(sender: UITextField) {
        becomeFirstResponder()
    }
}

class TextFieldWithButton: CustomTextField {
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rightBounds = CGRect(x: bounds.size.width - 70, y: 3, width: 67, height: 38)
        return rightBounds
    }
}

extension UITextField {
    var textWithVoxDomain: String {
        return (text ?? "") + ".voximplant.com"
    }
}

