/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import MBProgressHUD

protocol LoadingShowable where Self: UIViewController { }

extension LoadingShowable {
    func showLoading(title: String, details: String) {
        DispatchQueue.main.async {
            guard self.view.subviews.first(where: { $0 is MBProgressHUD }) == nil else { return }
            let progress = MBProgressHUD.showAdded(to: self.view, animated: true)
            progress.label.text = title
            progress.detailsLabel.text = details
        }
    }
    
    func hideProgress() {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}
