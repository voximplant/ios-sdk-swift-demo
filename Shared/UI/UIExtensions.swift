/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

extension UIViewController { // used to call segues with same id as a view controller type
    func performSegue(withIdentifier typeIdentifier: UIViewController.Type, sender: Any?) {
        performSegue(withIdentifier: String(describing: typeIdentifier), sender: sender)
    }
    
    func performSegue(withIdentifier typeIdentifier: UIViewController.Type, sender: Any?, _ completion: @escaping ()->Void) {
        self.performSegue(withIdentifier: typeIdentifier, sender: sender)
        DispatchQueue.main.async {
            completion()
        }
    }
    
    func canPerformSegue(withIdentifier id: String) -> Bool {
        guard let segues = self.value(forKey: "storyboardSegueTemplates") as? [NSObject] else { return false }
        return segues.first { $0.value(forKey: "identifier") as? String == id } != nil
    }
    
    func canPerformSegue(withIdentifier typeIdentifier: UIViewController.Type) -> Bool {
        return canPerformSegue(withIdentifier: String(describing: typeIdentifier))
    }
    
    func performSegueIfPossible(withIdentifier id: String?, sender: Any?) {
        guard let id = id, canPerformSegue(withIdentifier: id) else { return }
        performSegue(withIdentifier: id, sender: sender)
    }
    
    func performSegueIfPossible(withIdentifier typeIdentifier: UIViewController.Type, sender: Any?) {
        performSegueIfPossible(withIdentifier: String(describing: typeIdentifier), sender: sender)
    }
}

extension UIStoryboard {
    func instantiateViewController(withIdentifier typeIdentifier: UIViewController.Type) -> UIViewController {
        return instantiateViewController(withIdentifier: String(describing: typeIdentifier))
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

extension UIViewController {
    var topPresentedController: UIViewController {
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topPresentedController
        } else {
            return self
        }
    }
    
    var toppestViewController: UIViewController {
        if let navigationvc = self as? UINavigationController {
            if let navigationsTopViewController = navigationvc.topViewController {
                return navigationsTopViewController.topPresentedController
            } else {
                return navigationvc // no children
            }
        } else if let tabbarvc = self as? UITabBarController {
            if let selectedViewController = tabbarvc.selectedViewController {
                return selectedViewController.topPresentedController
            } else {
                return self // no children
            }
        } else if let firstChild = self.children.first {
            // other container's view controller
            return firstChild.topPresentedController
        } else {
            return self.topPresentedController
        }
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
