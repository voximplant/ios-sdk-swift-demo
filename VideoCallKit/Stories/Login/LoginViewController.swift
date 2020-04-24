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

    private func handleLogin(_ result: LoginResult) {
        self.hideProgress()
        switch(result) {
        case let .failure(error):
            AlertHelper.showError(message: error.localizedDescription, on: self)
        case .success:
            self.refreshUI()
            self.present(storyAssembler.assembleMain(), animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    private func refreshUI() {
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
