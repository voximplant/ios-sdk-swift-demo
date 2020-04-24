/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class MainViewController:
    UIViewController,
    AppLifeCycleDelegate,
    CallManagerDelegate,
    LoadingShowable,
    ErrorHandling
{
    @IBOutlet private var mainView: DefaultMainView!
    private let callManager: CallManager = sharedCallManager
    private let authService: AuthService = sharedAuthService
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let displayName = authService.loggedInUserDisplayName {
            mainView.setDisplayName(text: "Logged in as \(displayName)")
        }
        
        mainView.callTouchHandler = { username in
            Log.d("Calling \(String(describing: username))")
            PermissionsHelper.requestRecordPermissions(includingVideo: false) { error in
                if let error = error { self.handleError(error) }
                self.callManager.startOutgoingCall(username ?? "") { [weak self] result in
                    if case let .failure(error) = result {
                        AlertHelper.showError(message: error.localizedDescription, on: self)
                    } else if let strongSelf = self { // success
                        strongSelf.view.endEditing(true)
                        strongSelf.performSegue(withIdentifier: CallViewController.self, sender: strongSelf)
                    }
                }
            }
        }

        mainView.logoutTouchHandler = {
             self.authService.logout { [weak self] in
                 self?.dismiss(animated: true)
             }
         }
    }
    
    @IBAction func unwindSegueToMainController(_ unwindSegue: UIStoryboardSegue) { }
    
    @IBAction func unwindFromIncomingCall(_ unwindSegue: UIStoryboardSegue) {
        DispatchQueue.main.async {
            self.performSegueIfPossible(withIdentifier: IncomingCallViewController.self, sender: self)
        }
    }

    func reconnect() {
        Log.d("Reconnecting")
        showLoading(title: "Reconnecting", details: "Please wait...")
        authService.loginWithAccessToken { [weak self] result in
            guard let self = self else { return }
            self.hideProgress()
            
            switch(result) {
            case let .failure(error):
                AlertHelper.showError(message: error.localizedDescription, on: self)
            case let .success(userDisplayName):
                self.mainView.setDisplayName(text: "Logged in as \(userDisplayName)")
            }
        }
    }
    
    // MARK: - AppLifeCycleDelegate -
    func applicationDidBecomeActive(_ application: UIApplication) {
        reconnect()
    }
}


