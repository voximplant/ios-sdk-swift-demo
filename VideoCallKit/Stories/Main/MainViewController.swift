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
    @IBOutlet private var mainView: DefaultMainView!
    
    var callController: CXCallController! // DI
    var authService: AuthService! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let displayName = authService.loggedInUserDisplayName {
            mainView.setDisplayName(text: "Logged in as \(displayName)")
        }
        
        mainView.callTouchHandler = { username in
            Log.d("Calling \(String(describing: username))")
            PermissionsHelper.requestRecordPermissions(includingVideo: true) { [weak self] error in
                if let error = error {
                    self?.handleError(error)
                    return
                }
                let startCallAction = CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: username ?? ""))
                self?.callController.requestTransaction(with: startCallAction) { [weak self] error in
                    if let error = error, let self = self {
                        Log.e(error.localizedDescription)
                        AlertHelper.showError(message: error.localizedDescription, on: self)
                    }
                }
            }
        }
        
        mainView.logoutTouchHandler = { [weak self] in
            self?.authService.logout { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        let callViewController = storyAssembler.assembleCall()
        present(callViewController, animated: true) {
            callViewController.callObserver(callObserver, callChanged: call)
        }
    }
}
