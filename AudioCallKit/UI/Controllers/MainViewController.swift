/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CallKit

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

class MainViewController: UIViewController, CXCallObserverDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var callButton: ColoredButton!
    @IBOutlet weak var contactUsernameField: UITextField!
    @IBOutlet weak var userDisplayName: UILabel!
    
    // MARK: Properties
    fileprivate var callController: CXCallController = sharedCallController
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

        var loggedInAsDisplayName: String? = nil
        if let displayName = authService.loggedInUserDisplayName {
            loggedInAsDisplayName = "Logged in as \(displayName)"
        }
        userDisplayName.text = loggedInAsDisplayName
        
        hideKeyboardWhenTappedAround()
    }
    
    // MARK: Actions
    @IBAction func logoutTouch(_ sender: UIBarButtonItem) {
        authService.logout
        { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func callTouch(_ sender: AnyObject) {
        Log.d("Calling \(String(describing: contactUsernameField.text))")
        PermissionsManager.checkAudioPermisson {
            let contactUsername: String = self.contactUsernameField.text ?? ""
            let startOutgoingCall = CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: contactUsername))

            self.callController.requestTransaction(with: startOutgoingCall)
            { (error: Error?) in
                if let error = error {
                    UIHelper.ShowError(error: error.localizedDescription)
                    Log.e(error.localizedDescription)
                }
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
}


// MARK: CXCallObserverDelegate

extension MainViewController {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        performSegue(withIdentifier: CallViewController.self, sender: self)
        { [weak self] in
            let callViewController = self?.parent?.toppestViewController as? CallViewController
            callViewController?.callObserver(callObserver, callChanged: call)
        }
    }
}
