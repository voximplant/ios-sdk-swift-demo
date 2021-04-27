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

        mainView.configure(
            displayName: "",
            controller: self,
            callHandler: { [weak self] username in
                Log.d("Calling \(String(describing: username))")
                PermissionsHelper.requestRecordPermissions(includingVideo: true) { error in
                    if let error = error {
                        self?.handleError(error)
                        return
                    }
                    let startCallAction = CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: username ?? ""))
                    self?.callController.requestTransaction(with: startCallAction) { error in
                        if let error = error, let self = self {
                            Log.e(error.localizedDescription)
                            AlertHelper.showError(message: error.localizedDescription, on: self)
                        }
                    }
                }
            },
            logoutHandler: { [weak self] in
                self?.authService.logout {
                    self?.dismiss(animated: true)
                }
            }
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let displayName = authService.loggedInUserDisplayName {
            mainView.setDisplayName(text: "Logged in as \(displayName)")
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
