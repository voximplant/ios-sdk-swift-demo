/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import CallKit

class MainViewController: UIViewController, CXCallObserverDelegate {
    
    @IBOutlet weak var callButton: ColoredButton!
    @IBOutlet weak var contactUsernameField: UITextField!
    @IBOutlet weak var userDisplayName: UILabel!
    
    fileprivate var callController: CXCallController = sharedCallController
    fileprivate var authService: AuthService = sharedAuthService
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showSelfDisplayName()
        callButton.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSelfDisplayName()
    }
    
    // MARK: - Setup User Interface
    private func setupUI() {
        navigationItem.titleView = UIHelper.LogoView
        hideKeyboardWhenTappedAround()
    }
    
    private func showSelfDisplayName() {
        guard let displayName = authService.loggedInUserDisplayName else { return }
        userDisplayName.text = "Logged in as \(displayName)"
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
                    AlertHelper.showError(message: error.localizedDescription)
                    Log.e(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
    }
}


// MARK: - CXCallObserverDelegate
extension MainViewController {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        performSegue(withIdentifier: CallViewController.self, sender: self)
        { [weak self] in
            let callViewController = self?.parent?.toppestViewController as? CallViewController
            callViewController?.callObserver(callObserver, callChanged: call)
        }
    }
}
