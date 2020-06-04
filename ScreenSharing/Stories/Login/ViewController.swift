/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LoginViewController: UIViewController, LoadingShowable {
    @IBOutlet private var loginView: DefaultLoginView!
    var authService: AuthService! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.setTitle(text: "Video call demo")
        loginView.loginTouchHandler = { [weak self] username, password in
            Log.d("Logging in")
            self?.showLoading(title: "Connecting", details: "Please wait...")
            self?.authService.login(user: username.appendingVoxDomain, password: password) {
                [weak self] error in self?.handleLogin(with: error)
            }
        }
        if authService.possibleToLogin {
            Log.d("Logging in with token")
            self.showLoading(title: "Connecting", details: "Please wait...")
            self.authService.loginWithAccessToken { [weak self] error in
                self?.handleLogin(with: error)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    private func handleLogin(with error: Error?) {
        hideProgress()
        
        if let error = error {
            AlertHelper.showError(message: error.localizedDescription, on: self)
        } else {
            refreshUI()
            present(storyAssembler.assembleMain(), animated: true)
        }
    }
    
    private func refreshUI() {
        loginView.username = authService.loggedInUser?.replacingOccurrences(of: ".voximplant.com", with: "")
        loginView.password = ""
    }
}

