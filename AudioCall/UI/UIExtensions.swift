/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

extension UIViewController { // used to call segues with same id as a view controller type
    func performSegue(withIdentifier typeIdentifier: UIViewController.Type, sender: Any?) {
        return performSegue(withIdentifier: String(describing: typeIdentifier), sender: sender)
    }
}

extension UIViewController { // use this method to hide keyboard on tap on specific VC
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController { // use this method to create UIImage from any color
    func getImageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1000, height: 1000), true, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIViewController { // to change status bar color
    func changeStatusBarStyle(to style: UIStatusBarStyle) {
        UIApplication.shared.statusBarStyle = style
    }
}

extension UIViewController { // used to convert timeinterval to string
    func timeString(time: TimeInterval?) -> String { // converting time interval to mm:ss
        guard let convertableTime = time else { return "" }
        let minutes = Int(convertableTime) / 60 % 60
        let seconds = Int(convertableTime) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
}

extension UIImage { // used to create logo image with insets
    func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
}
