/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import SkyFloatingLabelTextField

class Theme {
    static let headerColor = UIColor(red: 0.14, green: 0.04, blue: 0.29, alpha: 1.0)
    static let color = UIColor(red: 0.40, green: 0.18, blue: 1.00, alpha: 1.0)
    static let cancelColor = UIColor(red:0.96, green:0.29, blue:0.37, alpha:1.0)

    static let minimumHeight: CGFloat = 40
    static let minimumWidth: CGFloat = 72

    static let defaultFont: UIFont! = UIFont(name: "Roboto-Regular", size: 14.0)
    static let titleFont: UIFont! = UIFont(name: "Roboto-Bold", size: 18.0)

    static let titleTextAttributes : [NSAttributedString.Key : Any]! = [NSAttributedString.Key.font: Theme.defaultFont, NSAttributedString.Key.foregroundColor: UIColor.white]

    static func applyTheme() {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barStyle = UIBarStyle.default
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = Theme.headerColor
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: Theme.titleFont, NSAttributedString.Key.foregroundColor: UIColor.white]

        UIBarButtonItem.appearance().setTitleTextAttributes(Theme.titleTextAttributes, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(Theme.titleTextAttributes, for: .highlighted)

        UILabel.appearance().font = Theme.defaultFont
    }
}

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

class Button: UIButton {
    func applyTheme() {
        self.adjustsImageWhenHighlighted = false
        self.adjustsImageWhenDisabled = false

        self.titleLabel?.font = Theme.defaultFont

        self.clipsToBounds = true
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1
        self.layer.borderColor = Theme.color.cgColor

        self.setBackgroundImage(UIImage.from(color: UIColor.white), for: .normal)
        self.setBackgroundImage(UIImage.from(color: Theme.color), for: .highlighted)
        self.setBackgroundImage(UIImage.from(color: Theme.color), for: .selected)
        self.setBackgroundImage(UIImage.from(color: Theme.color.withAlphaComponent(0.1)), for: .disabled)
        self.setTitleColor(Theme.color, for: .normal)
        self.setTitleColor(UIColor.white, for: .selected)
        self.setTitleColor(UIColor.white, for: .highlighted)

        self.setTitle(self.currentTitle?.uppercased(), for: .normal)

        self.addConstraint(NSLayoutConstraint(
                item: self,
                attribute: .height,
                relatedBy: .greaterThanOrEqual,
                toItem: nil,
                attribute: .width,
                multiplier: 1,
                constant: Theme.minimumHeight))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        applyTheme()
    }
}

class FilledButton: Button {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyTheme()
    }

    override func applyTheme() {
        super.applyTheme()

        self.setBackgroundImage(UIImage.from(color: Theme.color), for: .normal)
        self.setBackgroundImage(UIImage.from(color: UIColor.white), for: .highlighted)
        self.setBackgroundImage(UIImage.from(color: UIColor.white), for: .selected)
        self.setTitleColor(UIColor.white, for: .normal)
        self.setTitleColor(Theme.color, for: .highlighted)
        self.setTitleColor(Theme.color, for: .selected)
    }
}

class CancelButton: Button {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyTheme()
    }

    override func applyTheme() {
        super.applyTheme()

        self.layer.borderColor = Theme.cancelColor.cgColor

        self.setBackgroundImage(UIImage.from(color: UIColor.white), for: .normal)
        self.setBackgroundImage(UIImage.from(color: Theme.cancelColor), for: .highlighted)
        self.setBackgroundImage(UIImage.from(color: Theme.cancelColor), for: .selected)
        self.setTitleColor(Theme.cancelColor, for: .normal)
        self.setTitleColor(UIColor.white, for: .highlighted)
        self.setTitleColor(UIColor.white, for: .selected)
    }
}

class InputField: SkyFloatingLabelTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.applyTheme()
    }

    func applyTheme() {
        self.font = Theme.defaultFont
        self.placeholderFont = Theme.defaultFont
        self.titleFont = Theme.defaultFont

        self.selectedTitleColor = Theme.color
        self.selectedLineColor = Theme.color

        self.lineHeight = 1
        self.selectedLineHeight = 1

        self.placeholder = self.placeholder?.uppercased()

        self.tintColor = Theme.color
        self.textColor = Theme.headerColor

        self.addConstraint(NSLayoutConstraint(
                item: self,
                attribute: .height,
                relatedBy: .greaterThanOrEqual,
                toItem: nil,
                attribute: .width,
                multiplier: 1,
                constant: Theme.minimumHeight))
    }
}
