/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

extension UIViewController { // used to call segues with same id as a view controller type
    func performSegue(withIdentifier typeIdentifier: UIViewController.Type, sender: Any?) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: String(describing: typeIdentifier), sender: sender)
        }
    }
    
    func performSegue(withIdentifier typeIdentifier: UIViewController.Type, sender: Any?, _ completion: @escaping () -> Void) {
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


extension UIStoryboard {
    func instantiateViewController<Type: UIViewController>(of type: Type.Type) -> Type {
        instantiateViewController(withIdentifier: String(describing: type)) as! Type
    }
}
