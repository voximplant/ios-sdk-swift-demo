/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class LoginViewController: UIViewController, LoadingShowable {
    @IBOutlet private var loginView: DefaultLoginView!
    
    private let authService: AuthService = sharedAuthService
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.setTitle(text: "Audio call demo")
        
        let loginHandler: AuthService.LoginCompletion = { [weak self] error in
            guard let self = self else { return }
            self.hideProgress()
            if let error = error {
                AlertHelper.showError(message: error.localizedDescription, on: self)
            } else {
                self.performSegue(withIdentifier: MainViewController.self, sender: self)
            }
        }
        
        loginView.loginTouchHandler = { [weak self] username, password in
            Log.d("Manually Logging in with password")
            self?.showLoading(title: "Connecting", details: "Please wait...")
            self?.authService.login(user: username.appendingVoxDomain, password: password, loginHandler)
        }
        
        if authService.possibleToLogin {
            Log.d("Automatically Logging in with token")
            self.showLoading(title: "Connecting", details: "Please wait...")
            self.authService.loginWithAccessToken(loginHandler)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loginView.username = authService.loggedInUser?.replacingOccurrences(of: ".voximplant.com", with: "")
        loginView.password = ""
    }
}






