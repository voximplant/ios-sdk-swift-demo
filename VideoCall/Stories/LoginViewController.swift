/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LoginViewController:
    UIViewController,
    LoadingShowable
{
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    @IBOutlet private var loginView: DefaultLoginView!
    var authService: AuthService! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.setTitle(text: "Video call demo")
        
        let loginHandler: AuthService.LoginCompletion = { [weak self] error in
            guard let self = self else { return }
            self.hideProgress()
            if let error = error {
                AlertHelper.showError(message: error.localizedDescription, on: self)
            } else {
                self.present(self.storyAssembler.main, animated: true)
            }
        }
        
        loginView.loginTouchHandler = { [weak self] username, password in
            Log.d("Manually Logging in with password")
            self?.showLoading(title: "Connecting", details: "Please wait...")
            self?.authService.login(user: username.appendingVoxDomain, password: password, loginHandler)
        }
        
        if authService.possibleToLogin {
            Log.d("Automatically Logging in with token")
            showLoading(title: "Connecting", details: "Please wait...")
            authService.loginWithAccessToken(loginHandler)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loginView.username = authService.loggedInUser?.replacingOccurrences(of: ".voximplant.com", with: "")
        loginView.password = ""
    }
}
