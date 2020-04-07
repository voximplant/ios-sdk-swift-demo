/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class LoginViewController: UIViewController {
    
    // MARK: Properties
    private let authService: AuthService = sharedAuthService // service to manage authorization
    private var tokenExpireDate: String?  { // used to get correct access token expire date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let date = authService.possibleToLogin() else { return nil }
        return formatter.string(from: date)
    }
    private var SDKVersion: String { // used to generate string with current versions of sdk and webrtc used
        return String(format: "VoximplantSDK %@\nWebRTC %@",
                      arguments: [VIClient.clientVersion(),
                                  VIClient.webrtcVersion()])
    }
    var userDisplayName: String? // used to save and transfer userDisplayName between controllers
    
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
        loginUserField.text = authService.loggedInUser?.replacingOccurrences(of: ".voximplant.com", with: "")
        loginPasswordField.text = ""
        if let expireDate = tokenExpireDate {
            tokenContainerView.isHidden = false
            tokenLabel.text = "Token will expire at:\n\(expireDate)"
        } else {
            tokenContainerView.isHidden = true
        }
    }
    
    // MARK: Actions
    @IBAction func loginTouch(sender: AnyObject) {
        Log.d("Logging in")
        UIHelper.ShowProgress(title: "Connecting", details: "Please wait...", viewController: self)
        authService.login(user: loginUserField.textWithVoxDomain, password: loginPasswordField.text!)
        { [weak self] (result: Result<String,Error>) in
            
            guard let strongSelf = self else { return }
            
            UIHelper.HideProgress(on: strongSelf)
            
            switch(result) {
            case let .failure(error):
                AlertHelper.showError(message: error.localizedDescription)
            case let .success(userDisplayName):
                strongSelf.refreshUI()
                strongSelf.userDisplayName = userDisplayName
                strongSelf.performSegue(withIdentifier: MainViewController.self, sender: strongSelf)
            }
        }
    }
    
    @IBAction func loginWithTokenTouch(sender: AnyObject?) {
        Log.d("Logging in with token")
        UIHelper.ShowProgress(title: "Connecting", details: "Please wait...", viewController: self)
        
        authService.loginWithAccessToken { [weak self] result in
            
            UIHelper.HideProgress(on: self!)
            
            self?.refreshUI()
            
            switch(result) {
            case let .failure(error):
                AlertHelper.showError(message: error.localizedDescription)
            case let .success(userDisplayName):
                self?.userDisplayName = userDisplayName
                self?.performSegue(withIdentifier: MainViewController.self, sender: self)
            }
        }
    }
    
}






