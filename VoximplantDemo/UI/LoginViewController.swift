/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit;
import Dispatch;
import MBProgressHUD;
import CocoaLumberjack;
import VoxImplantSDK;

class LoginViewController: BaseViewController {
    var progress : MBProgressHUD?

    @IBOutlet var gatewayField: UITextField?
    @IBOutlet var userField: UITextField?
    @IBOutlet var passwordField: UITextField?
    @IBOutlet var loginWithTokenButton: UIButton?
    @IBOutlet var tokenLabel: UILabel?
    @IBOutlet var versionLabel: UILabel?

    var tokenIsSaved: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        let logoImage = UIImage(named: "Logo")

        let titleView = UIImageView(image: logoImage!.imageWithInsets(insets: UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)))
        titleView.contentMode = .scaleAspectFit

        let height = self.navigationController?.navigationBar.frame.size.height ?? 0
        var frame = titleView.frame
        frame.size.height = height
        titleView.frame = frame

        self.navigationItem.titleView = titleView

        self.versionLabel?.text = String(format: "VoximplantSDK v%@\nWebRTC v%@", arguments: [VIClient.clientVersion(), VIClient.webrtcVersion()])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.refreshView()
    }

    func refreshView() {
        self.gatewayField?.text = Settings.shared.serverGateway
        self.userField?.text = Settings.shared.userLogin

        if let token = Settings.shared.accessToken, let tokenExpire = Settings.shared.refreshExpire,
           !token.isEmpty && Date() < tokenExpire  {
            self.loginWithTokenButton?.isHidden = false
            self.tokenLabel?.isHidden = false
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            self.tokenLabel?.text = "Token will expire at:\n\(formatter.string(from: Settings.shared.accessExpire!))"
        } else {
            self.loginWithTokenButton?.isHidden = true
            self.tokenLabel?.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginTouched(sender: AnyObject) {
        let login = self.userField?.text
        let password = self.passwordField?.text
        if (login!.isEmpty || password!.isEmpty) {
            UIHelper.ShowError(error: "Login and password must not be empty")
            return
        }

        self.progress = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.progress?.label.text = "Connecting"
        self.progress?.detailsLabel.text = "Please wait..."

        let voxImplant = AppDelegate.instance().voxImplant!

        voxImplant.setGateway(gateway: self.gatewayField?.text)
        voxImplant.login(user: self.userField?.text, password: self.passwordField?.text, success: { (displayName, authParams) in
            self.progress?.hide(animated: true)
            self.refreshView()

            Settings.shared.displayName = displayName
        }, failure: { (error) in
            self.progress?.hide(animated: true)
            self.refreshView()

            UIHelper.ShowError(error: error.localizedDescription)
        })
    }

    @IBAction func loginWithTokenTouched(sender: AnyObject?) {
        let login = self.userField?.text
        if (login!.isEmpty) {
            UIHelper.ShowError(error: "Login must not be empty")
            return
        }

        self.progress = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.progress?.label.text = "Connecting"
        self.progress?.detailsLabel.text = "Please wait..."

        let voxImplant = AppDelegate.instance().voxImplant!

        voxImplant.setGateway(gateway: self.gatewayField?.text)
        voxImplant.loginWithToken(user: self.userField?.text!, success: { (displayName, authParams) in
            self.progress?.hide(animated: true)
        }, failure: { (error) in
            self.progress?.hide(animated: true)
            UIHelper.ShowError(error: error.localizedDescription)
        })
    }

    @IBAction func loginWithOTKTouched(sender: AnyObject?) {
        let login = self.userField?.text
        let password = self.passwordField?.text
        if (login!.isEmpty || password!.isEmpty) {
            UIHelper.ShowError(error: "Login and password must not be empty")
            return
        }

        self.progress = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.progress?.label.text = "Connecting"
        self.progress?.detailsLabel.text = "Please wait..."

        let voxImplant = AppDelegate.instance().voxImplant!

        voxImplant.setGateway(gateway: self.gatewayField?.text)
        voxImplant.loginWithOneTimeKey(user: self.userField?.text!, password: self.passwordField?.text, success: { (displayName, authParams) in
            self.progress?.hide(animated: true)
            self.refreshView()

            Settings.shared.displayName = displayName
        }, failure: { (error) in
            self.progress?.hide(animated: true)
            self.refreshView()

            UIHelper.ShowError(error: error.localizedDescription)
        })
    }

    override func voxDidLoggedIn(_ voximplant: VoxController!) {
        super.voxDidLoggedIn(voximplant)

        self.performSegue(withIdentifier: "MainController", sender: self)
    }
}

extension UIImage {
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
