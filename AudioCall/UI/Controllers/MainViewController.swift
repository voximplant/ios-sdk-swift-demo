/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class MainViewController: UIViewController, AppLifeCycleDelegate, CallManagerDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var contactUsernameField: UITextField!
    @IBOutlet weak var userDisplayName: UILabel!
    
    // MARK: Properties
    fileprivate var callManager: CallManager = sharedCallManager
    fileprivate var authService: AuthService = sharedAuthService
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        callButton.isEnabled = true
    }
    
    // MARK: Setup User Interface
    private func setupUI() {
        navigationItem.titleView = UIHelper.LogoView
        hideKeyboardWhenTappedAround()
        showSelfDisplayName()
    }
    
    private func showSelfDisplayName() {
        guard let displayName = authService.loggedInUserDisplayName else { return }
        userDisplayName.text = "Logged in as \(displayName)"
    }
    
    // MARK: Actions
    @IBAction func logoutTouch(_ sender: UIBarButtonItem) {
        authService.logout {
            [weak self] in
                self?.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func callTouch(_ sender: AnyObject) {
        Log.d("Calling \(String(describing: contactUsernameField.text))")
        PermissionsManager.checkAudioPermisson {
            let contactUsername: String = self.contactUsernameField.text ?? ""
            self.callManager.startOutgoingCall(contactUsername) { [weak self] (result: Result<(), Error>) in
                if case let .failure(error) = result {
                    AlertHelper.showError(message: error.localizedDescription)
                } else if let strongSelf = self { // success
                    strongSelf.prepareUIToCall() // block user interaction
                    strongSelf.performSegue(withIdentifier: CallViewController.self, sender: strongSelf)
                }
            }
        }
    }
    
    @IBAction func unwindSegueToMainController(_ unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindFromIncomingCall(_ unwindSegue: UIStoryboardSegue) {
        DispatchQueue.main.async {
            self.performSegueIfPossible(withIdentifier: IncomingCallViewController.self, sender: self)
        }
    }
    
    // MARK: Call
    private func prepareUIToCall() {
        callButton.isEnabled = false
        view.endEditing(true)
    }

    func reconnect() {
        Log.d("Reconnecting")
        UIHelper.ShowProgress(title: "Reconnecting", details: "Please wait...", viewController: self)
        authService.loginWithAccessToken
        { [weak self] result in
            if let strongSelf = self {
                strongSelf.callButton.isEnabled = true
                
                switch(result) {
                case let .failure(error):
                    AlertHelper.showError(message: error.localizedDescription, on: strongSelf)
                case let .success(userDisplayName):
                    strongSelf.userDisplayName.text = "Logged in as \(userDisplayName)"
                }
                UIHelper.HideProgress(on: strongSelf)
            }
        }
    }
    
    // MARK: AppLifeCycleDelegate
    func applicationDidBecomeActive(_ application: UIApplication) {
        reconnect()
    }
}

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}


