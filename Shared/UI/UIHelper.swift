/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import MBProgressHUD

class UIHelper {    
    class var LogoView: UIImageView? { // used to return logo for nav bar
        let image = #imageLiteral(resourceName: "Logo").imageWithInsets(insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }
    
    // MARK: Progress HUD Methods
    // Shows or hides progress UI Elelment with animated cirle to indicate user that something is happening
    class func ShowProgress(title:String, details: String, viewController: UIViewController) {
        DispatchQueue.main.async {
            guard viewController.view.subviews.first(where: { $0 is MBProgressHUD }) == nil else { return }
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
    
    class func getImageWithColor(color: UIColor) -> UIImage { // use this method to create UIImage from any color
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
