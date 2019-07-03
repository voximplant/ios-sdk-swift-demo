/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import AVFoundation
import Dispatch
import MBProgressHUD

class UIHelper {
    fileprivate static var incomingCallAlert: UIAlertController?
    fileprivate static var player: AVAudioPlayer?
    
    class var LogoView: UIImageView? { // used to return logo for nav bar
        let image = #imageLiteral(resourceName: "Logo").imageWithInsets(insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }
    
    
    // MARK: Show errors methods
    class func ShowError(error: String!, action: UIAlertAction? = nil, controller: UIViewController? = nil) {
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController  {
                
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                
                if let alertAction = action {
                    alert.addAction(alertAction)
                }
                
                if let specifiedController = controller {
                    specifiedController.present(alert, animated: true, completion: nil)
                } else {
                    let controllerToUse = UIHelper.topPresentedController(controller: rootViewController)
                    controllerToUse.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: Progress HUD Methods
    // Shows or hides progress UI Elelment with animated cirle to indicate user that something is happening
    class func ShowProgress(title:String, details: String, viewController: UIViewController) {
        DispatchQueue.main.async {
            let progress = MBProgressHUD.showAdded(to: viewController.view, animated: true)
            progress.label.text = title
            progress.detailsLabel.text = details
        }
    }
    
    class func HideProgress(on viewController: UIViewController) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: viewController.view, animated: true)
        }
    }
    
    class func topPresentedController(controller: UIViewController) -> UIViewController { // used to get most top controller of the screen
        guard let presentedController = controller.presentedViewController else { return controller }
        return topPresentedController(controller: presentedController)
    }
    
}
