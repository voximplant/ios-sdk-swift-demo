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
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    @IBOutlet var loginView: DefaultLoginView!
    
    private let authService: AuthService = sharedAuthService
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let loginHandler: AuthService.LoginCompletion = { [weak self] error in
            guard let self = self else { return }
            self.hideProgress()
            if let error = error {
                AlertHelper.showError(message: error.localizedDescription, on: self)
            } else {
                self.performSegue(withIdentifier: MainViewController.self, sender: self)
            }
        }

        loginView.configure(
            title: "Audio call demo",
            controller: self,
            loginHandler: { [weak self] username, password, nodeString in
                Log.d("Manually Logging in with password")
                self?.showLoading(title: "Connecting", details: "Please wait...")
                self?.authService.login(
                    user: username.appendingVoxDomain,
                    password: password,
                    nodeString: nodeString,
                    loginHandler
                )
            }
        )

        if authService.possibleToLogin {
            Log.d("Automatically Logging in with token")
            self.showLoading(title: "Connecting", details: "Please wait...")
            self.authService.loginWithAccessToken(completion: loginHandler)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loginView.username = authService.loggedInUser?.replacingOccurrences(
            of: ".voximplant.com",
            with: ""
        )
        loginView.password = ""
    }
    
    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        performSegue(withIdentifier: MainViewController.self, sender: self) { [weak self] in
            let mainViewController = self?.parent?.toppestViewController as? MainViewController
            mainViewController?.callObserver(callObserver, callChanged: call)
        }
    }
}
