/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

extension UITextField {
    var textWithVoxDomain: String {
        return (text ?? "") + ".voximplant.com"
    }
}

class TextFieldWithButton: CustomTextField {
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rightBounds = CGRect(x: bounds.size.width - 70, y: 3, width: 67, height: 38)
        return rightBounds
    }
}

class CustomTextField: UITextField { // this class used to work with textfiled and reuse it
    
    @IBOutlet override var rightView: UIView? {
        get {
            return super.rightView
        }
        set {
            super.rightView = newValue
        }
    }
    var padding: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 100)
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
        setValue(UIColor.darkGray, forKeyPath: "placeholderLabel.textColor")
        layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        layer.shadowRadius = 15
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.03
        layer.masksToBounds = true
        layer.cornerRadius = 8
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 0.3
        rightViewMode = .always
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    
    
    @IBAction func nextField(sender: UITextField) {
        becomeFirstResponder()
    }
}
