/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import CallKit

final class MainViewController:
    UIViewController,
    CXCallObserverDelegate,
    LoadingShowable,
    ErrorHandling
{
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    @IBOutlet private var mainView: DefaultMainView!
    
    private let callController: CXCallController = sharedCallController
    private let authService: AuthService = sharedAuthService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.callTouchHandler = { [weak self] username in
            Log.d("Calling \(String(describing: username))")
            PermissionsHelper.requestRecordPermissions { error in
                if let error = error {
                    self?.handleError(error)
                    return
                }
                let startCallAction = CXStartCallAction(
                    call: UUID(),
                    handle: CXHandle(type: .generic, value: username ?? "")
                )
                self?.callController.requestTransaction(with: startCallAction) { error in
                    if let error = error, let self = self {
                        AlertHelper.showError(message: error.localizedDescription, on: self)
                        Log.e(error.localizedDescription)
                    }
                }
            }
        }
        
        mainView.logoutTouchHandler = { [weak self] in
            self?.authService.logout {
                self?.dismiss(animated: true)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let displayName = authService.loggedInUserDisplayName {
            mainView.setDisplayName(text: "Logged in as \(displayName)")
        }
    }

    @IBAction func unwindSegue(segue: UIStoryboardSegue) { }
    
    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        performSegue(withIdentifier: CallViewController.self, sender: self) { [weak self] in
            let callViewController = self?.parent?.toppestViewController as? CallViewController
            callViewController?.callObserver(callObserver, callChanged: call)
        }
    }
}