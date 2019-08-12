/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CallKit

class LoginViewController: UIViewController {
    
    // MARK: Properties
    private let authService: AuthService = sharedAuthService
    private var tokenExpireDate: String?  {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let date = authService.possibleToLogin(for: loginUserField.textWithVoxDomain) else { return nil }
        return formatter.string(from: date)
    }
    private var SDKVersion: String {
        return String(format: "VoximplantSDK %@\nWebRTC %@",
                      arguments: [VIClient.clientVersion(),
                                  VIClient.webrtcVersion()])
    }
    var userDisplayName: String?
    
    // MARK: Outlets
    @IBOutlet weak var loginUserField: UITextField!
    @IBOutlet weak var loginPasswordField: UITextField!
    @IBOutlet weak var loginWithTokenButton: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var tokenContainerView: UIView!
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshUI()
    }
    
    // MARK: UI methods
    private func setupUI() {
        navigationItem.titleView = UIHelper.LogoView
        
        versionLabel?.text = SDKVersion
        
        hideKeyboardWhenTappedAround()
    }
    
    private func refreshUI() {
        loginUserField.text = authService.lastLoggedInUser?.fullUsername.replacingOccurrences(of: ".voximplant.com", with: "")
        
        if let expireDate = tokenExpireDate {
            tokenContainerView.isHidden = false
            tokenLabel.text = "Token will expire at:\n\(expireDate)"
        } else {
            tokenContainerView.isHidden = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: Actions
    @IBAction func loginTouch(sender: AnyObject) {
        Log.d("Logging in")
        UIHelper.ShowProgress(title: "Connecting", details: "Please wait...", viewController: self)
        authService.login(user: loginUserField.textWithVoxDomain, password: loginPasswordField.text!)
        { [weak self] (result: Result<String,Error>) in

            guard let sself = self else { return }
            
            UIHelper.HideProgress(on: sself)
            
            switch(result) {
            case let .failure(error):
                UIHelper.ShowError(error: error.localizedDescription)
            case let .success(userDisplayName):
                sself.refreshUI()
                sself.userDisplayName = userDisplayName
                sself.performSegue(withIdentifier: MainViewController.self, sender: sself)
            }
        }
    }
    
    @IBAction func loginWithTokenTouch(sender: AnyObject?) {
        Log.d("Logging in with token")
        UIHelper.ShowProgress(title: "Connecting", details: "Please wait...", viewController: self)
        
        authService.loginWithAccessToken(user: loginUserField.textWithVoxDomain)
        { [weak self] result in
            
            guard let sself = self else { return }
            
            UIHelper.HideProgress(on: sself)
            sself.refreshUI()
            
            switch(result) {
            case let .failure(error):
                UIHelper.ShowError(error: error.localizedDescription)
            case let .success(userDisplayName):
                sself.userDisplayName = userDisplayName
                sself.performSegue(withIdentifier: MainViewController.self, sender: sself)
            }
        }
    }
    
}

// MARK: CXCallObserverDelegate

extension LoginViewController: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
}

extension UINavigationController {
    open override var prefersStatusBarHidden: Bool {
        return false
    }
}
