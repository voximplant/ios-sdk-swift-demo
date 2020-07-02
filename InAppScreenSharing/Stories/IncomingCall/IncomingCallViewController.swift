/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class IncomingCallViewController: UIViewController, ErrorHandling {
    @IBOutlet private var incomingCallView: DefaultIncomingCallView!
    
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        incomingCallView.displayName = callManager.managedCallWrapper?.displayName ?? callManager.managedCallWrapper?.callee
        
        incomingCallView.declineHandler = { [weak self] in
            Log.d("Call declined from incomingCall view")
            do {
                try self?.callManager.endCall()
            } catch (let error) {
                Log.e(error.localizedDescription)
            }
            self?.dismiss(animated: true)
        }
        
        incomingCallView.acceptHandler = { [weak self] in
            Log.d("Call accepted from incomingCall view")
            PermissionsHelper.requestRecordPermissions(
                includingVideo: true,
                completion: { [weak self] error in
                    if let error = error {
                        self?.handleError(error)
                        return
                    }
                    
                    if let self = self {
                        weak var presentingViewController = self.presentingViewController
                        self.dismiss(animated: true) {
                            presentingViewController?.present(self.storyAssembler.call, animated: true)
                        }
                    }
                }
            )
        }
        
        callManager.callObserver = { [weak self] call in
            guard let self = self else { return }
            if case .ended (let reason) = call.state {
                if case .disconnected = reason {
                    self.dismiss(animated: true)
                }
                if case .failed (let message) = reason {
                    weak var presentingViewController = self.presentingViewController
                    self.dismiss(animated: true) {
                        presentingViewController?.present(
                            self.storyAssembler.callFailed(
                                callee: call.callee,
                                displayName: call.displayName ?? call.callee,
                                reason: message
                            ),
                            animated: true)
                    }
                }
            }
        }
    }
}
