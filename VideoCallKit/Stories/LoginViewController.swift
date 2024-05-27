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
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    @IBOutlet private var loginView: DefaultLoginView!
    var authService: AuthService! // DI

    override func viewDidLoad() {
        super.viewDidLoad()

        let loginHandler: AuthService.LoginCompletion = { [weak self] error in
            guard let self = self else { return }
            self.hideProgress()
            if let error = error {
                AlertHelper.showError(message: error.localizedDescription, on: self)
            } else {
                self.present(storyAssembler.assembleMain(), animated: true)
            }
        }

        loginView.configure(
            title: "Video call demo",
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
            showLoading(title: "Connecting", details: "Please wait...")
            authService.loginWithAccessToken(completion: loginHandler)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loginView.username = authService.loggedInUser?.replacingOccurrences(of: ".voximplant.com", with: "")
        loginView.password = ""
    }

    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        hideProgress()
        let mainViewController = storyAssembler.assembleMain()
        present(mainViewController, animated: true) {
            mainViewController.callObserver(callObserver, callChanged: call)
        }
    }
}
