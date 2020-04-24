/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class LoginViewController: UIViewController, LoadingShowable {
    @IBOutlet private var loginView: DefaultLoginView!
    private let authService: AuthService = sharedAuthService
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.setTitle(text: "Audio call demo")
        loginView.loginTouchHandler = { [weak self] username, password in
            Log.d("Logging in")
            self?.showLoading(title: "Connecting", details: "Please wait...")
            self?.authService.login(user: username.appendingVoxDomain, password: password) {
                [weak self] result in self?.handleLogin(result)
            }
        }
        if authService.possibleToLogin {
            Log.d("Logging in with token")
            self.showLoading(title: "Connecting", details: "Please wait...")
            self.authService.loginWithAccessToken { [weak self] result in
                self?.handleLogin(result)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    private func handleLogin(_ result: LoginResult) {
        self.hideProgress()
        switch(result) {
        case let .failure(error):
            AlertHelper.showError(message: error.localizedDescription, on: self)
        case .success:
            self.refreshUI()
            self.performSegue(withIdentifier: MainViewController.self, sender: self)
        }
    }
     
    private func refreshUI() {
        loginView.username = authService.loggedInUser?.replacingOccurrences(of: ".voximplant.com", with: "")
        loginView.password = ""
    }
}






