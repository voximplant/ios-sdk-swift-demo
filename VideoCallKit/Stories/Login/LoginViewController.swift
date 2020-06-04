/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import CallKit

final class LoginViewController:
    UIViewController,
    CXCallObserverDelegate,
    LoadingShowable
{
    @IBOutlet private var loginView: DefaultLoginView!
    var authService: AuthService! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginView.setTitle(text: "Video call demo")
        
        let loginHandler: AuthService.LoginCompletion = { [weak self] error in
            guard let self = self else { return }
            self.hideProgress()
            if let error = error {
                AlertHelper.showError(message: error.localizedDescription, on: self)
            } else {
                self.present(storyAssembler.assembleMain(), animated: true)
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
    
    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        let mainViewController = storyAssembler.assembleMain()
        present(mainViewController, animated: true) {
            mainViewController.callObserver(callObserver, callChanged: call)
        }
    }
}
