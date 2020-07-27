/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class IncomingCallViewController: UIViewController, ErrorHandling {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    @IBOutlet private var incomingCallView: DefaultIncomingCallView!
    
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let wrapper = callManager.managedCallWrapper {
            incomingCallView.displayName = wrapper.displayName ?? wrapper.callee
        }
        
        incomingCallView.declineHandler = { [weak self] in
            Log.d("Call declined from incomingCall view")
            do {
                try self?.callManager.endCall()
            } catch (let error) {
                self?.dismiss(animated: true)
                Log.e(error.localizedDescription)
            }
        }
        
        incomingCallView.acceptHandler = { [weak self] in
            Log.d("Call accepted from incomingCall view")
            PermissionsHelper.requestRecordPermissions { [weak self] error in
                if let error = error {
                    self?.handleError(error)
                    return
                }
                
                if let self = self {
                    self.navigationController?.setViewControllers(
                        [self.storyAssembler.call],
                        animated: true
                    )
                }
            }
        }
        
        callManager.callObserver = { [weak self] call in
            guard let self = self else { return }
            if case .ended (let reason) = call.state {
                if case .disconnected = reason {
                    self.dismiss(animated: true)
                }
                if case .failed (let message) = reason {
                    self.navigationController?.setViewControllers(
                        [self.storyAssembler.callFailed(
                            callee: call.callee,
                            displayName: call.displayName ?? call.callee,
                            reason: message)
                        ],
                        animated: true
                    )
                }
            }
        }
    }
}
