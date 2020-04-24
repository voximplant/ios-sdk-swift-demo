/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

extension String {
    var appendingVoxDomain: String { "\(self).voximplant.com" }
}

final class DefaultTextField: UITextField {
    var padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    
    private let placeholerAttributes: [NSAttributedString.Key: Any]
        = [NSAttributedString.Key.foregroundColor : Color.secondaryWhite]

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }

    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
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
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: placeholerAttributes)
        layer.borderWidth = 1
        layer.borderColor = Color.secondaryWhite.cgColor
        layer.cornerRadius = Theme.defaultCornerRadius
    }
}
