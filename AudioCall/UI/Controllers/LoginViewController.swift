/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class LoginViewController: UIViewController {
    
    // MARK: Properties
    private let authService: AuthService = sharedAuthService // service to manage authorization
    private var tokenExpireDate: String?  { // used to get correct access token expire date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let date = authService.possibleToLogin(for: (loginUserField.text ?? "") + ".voximplant.com") else { return nil }
        return formatter.string(from: date)
    }
    private var SDKVersion: String { // used to generate string with current versions of sdk and webrtc used
        return String(format: "VoximplantSDK %@\nWebRTC %@",
                      arguments: [VIClient.clientVersion(),
                                  VIClient.webrtcVersion()])
    }
    var userDisplayName: String? // used to save and transfer userDisplayName between controllers
    
    var user: User {
        let username = loginUserField.text ?? ""
        let displayName = userDisplayName ?? ""
        return User(id: username, displayName: displayName)
    }
    
    // MARK: Outlets
    @IBOutlet weak var loginUserField: UITextField!
    @IBOutlet weak var loginPasswordField: UITextField!
    @IBOutlet weak var loginWithTokenButton: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    @IBOutlet weak var loginButtonsSeparatorView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet var loginButtons: [UIButton]!
    
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
        
        for button in loginButtons {
            button.layer.borderColor = #colorLiteral(red: 0.4, green: 0.1803921569, blue: 1, alpha: 1)
            button.setBackgroundImage(getImageWithColor(color: #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)), for: .highlighted)
            button.setBackgroundImage(getImageWithColor(color: #colorLiteral(red: 0.4, green: 0.1803921569, blue: 1, alpha: 1)), for: .normal)
        }
        
        hideKeyboardWhenTappedAround()
        
        changeStatusBarStyle(to: .lightContent)
    }
    
    private func refreshUI() {
        loginUserField.text = authService.lastLoggedInUser?.id.replacingOccurrences(of: ".voximplant.com", with: "")
        
        guard let token = tokenExpireDate else {
            loginWithTokenButton.isHidden = true
            tokenLabel.isHidden = true
            loginButtonsSeparatorView.isHidden = true
            return
        }
        
        tokenLabel.text = "Token will expire at:\n\(token)"
    }
    
    // MARK: Actions
    @IBAction func loginTouch(sender: AnyObject) {
        guard let login = loginUserField.text,
            let password = loginPasswordField.text else {
                UIHelper.ShowError(error: "Username or password is missing")
                return
        }
        
        UIHelper.ShowProgress(title: "Connecting", details: "Please wait...", viewController: self)
        
        authService.login(user: login + ".voximplant.com", password: password) { [weak self] result in
            
            UIHelper.HideProgress(on: self!)
            
            switch(result) {
            case let .failure(error):
                UIHelper.ShowError(error: error.localizedDescription)
            case let .success(userDisplayName):
                self?.refreshUI()
                self?.userDisplayName = userDisplayName
                self?.performSegue(withIdentifier: MainViewController.self, sender: self)
            }
        }
    }
    
    @IBAction func loginWithTokenTouch(sender: AnyObject?) {
        
        UIHelper.ShowProgress(title: "Connecting", details: "Please wait...", viewController: self)
        
        authService.loginWithAccessToken(user: self.loginUserField!.text! + ".voximplant.com") { [weak self] result in
            
            UIHelper.HideProgress(on: self!)
            
            self?.refreshUI()
            
            switch(result) {
            case let .failure(error):
                UIHelper.ShowError(error: error.localizedDescription)
            case let .success(userDisplayName):
                self?.userDisplayName = userDisplayName
                self?.performSegue(withIdentifier: MainViewController.self, sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // sharing data about user with next controller in segue destination
        guard let controller = segue.destination as? MainViewController else { return }
        
        controller.loggedInUser = user
    }
    
}






