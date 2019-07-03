/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class MainViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var contactUsernameField: UITextField!
    @IBOutlet weak var userDisplayName: UILabel!
    
    // MARK: Properties
    fileprivate var callManager: CallManager = sharedCallManager
    fileprivate var authService: AuthService = sharedAuthService
    
    var loggedInUser: User!
    var endpointUsername: String?
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callManager.delegate = self
        
        setupUI()
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        callButton.isEnabled = true
        
        changeStatusBarStyle(to: .lightContent)
    }
    
    // MARK: Setup User Interface
    private func setupUI() {
        navigationItem.titleView = UIHelper.LogoView

        userDisplayName.text = "Logged in as \(loggedInUser.displayName)"
        
        callButton.layer.borderColor = #colorLiteral(red: 0.4, green: 0.1803921569, blue: 1, alpha: 1)
        callButton.setBackgroundImage(getImageWithColor(color: #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)), for: .highlighted)
        callButton.setBackgroundImage(getImageWithColor(color: #colorLiteral(red: 0.4, green: 0.1803921569, blue: 1, alpha: 1)), for: .normal)
    }
    
    // MARK: Actions
    @IBAction func logoutTouch(_ sender: UIBarButtonItem) {
        authService.disconnect { result in
            switch (result) {
            case .success():
                self.navigationController?.popViewController(animated: true)
            case let .failure(error):
                UIHelper.ShowError(error: error.localizedDescription)
            }
        }
    }
    
    @IBAction func callTouch(_ sender: AnyObject) {
        Log.d("Calling \(String(describing: contactUsernameField.text))")
        
        AVCaptureDevice.requestPermissionIfNeeded(for: .audio)
        
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else { return }
        
        // Voximplant SDK could handle will empty username.
        let contactUsername: String = contactUsernameField.text ?? ""
        callManager.startOutgoingCall(contactUsername)
        { [weak self] (result: Result<(), Error>) in
            if case let .failure(error) = result {
                UIHelper.ShowError(error: error.localizedDescription)
            } else if let sself = self { // success
                sself.prepareUIToCall() // block user interaction
                sself.endpointUsername = sself.contactUsernameField.text
                sself.performSegue(withIdentifier: CallViewController.self, sender: sself)
            }
        }
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
    }
    
    // MARK: Call
    private func prepareUIToCall() {
        callButton.isEnabled = false
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CallViewController {
            controller.endpointUsername = endpointUsername ?? ""
        }
    }
    
    // MARK: Supporting methods
    func reconnect() {
        UIHelper.ShowProgress(title: "Reconnecting", details: "Please wait...", viewController: self)
        
        authService.loginWithAccessToken(user: loggedInUser.id + ".voximplant.com")
        { [weak self] result in
            UIHelper.HideProgress(on: self!)
            self?.callButton.isEnabled = true
            
            switch(result) {
            case let .failure(error):
                UIHelper.ShowError(error: error.localizedDescription, controller: self)
            case let .success(userDisplayName):
                self?.userDisplayName.text = "Logged in as \(userDisplayName)"
            }
        }
    }
}

// MARK: CallManager delegate
extension MainViewController: CallManagerDelegate {
    func notifyIncomingCall(_ descriptor: VICall) {
        performSegue(withIdentifier: IncomingCallViewController.self, sender: self)
    }
    
    func cancelIncomingCall(_ descriptor: VICall) {
        presentedViewController?.dismiss(animated: false, completion: nil)
    }
}


