/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class CallFailedViewController: UIViewController {
    @IBOutlet private var callFailedView: DefaultCallFailedView!
    
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    var failReason: String! // DI
    var user: String! // DI
    var displayName: String! // DI
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callFailedView.displayName = displayName
        callFailedView.reason = failReason
        
        callManager.didReceiveIncomingCall = { [weak self] in
            guard let self = self else { return }
            
            weak var presentingViewController = self.presentingViewController
            self.dismiss(animated: true) {
                presentingViewController?.present(self.storyAssembler.incomingCall, animated: true)
            }
        }
        
        callFailedView.cancelHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        callFailedView.callBackHandler = { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.callManager.makeOutgoingCall(to: self.user)
                
                weak var presentingViewController = self.presentingViewController
                self.dismiss(animated: true) {
                    presentingViewController?.present(self.storyAssembler.call, animated: true)
                }
                
            } catch (let error) {
                Log.e("Error during call back \(error.localizedDescription)")
                AlertHelper.showAlert(
                    title: "Error",
                    message: error.localizedDescription,
                    actions: [
                        UIAlertAction(title: "Dismiss", style: .cancel) { _ in
                            self.dismiss(animated: true)
                        }
                    ],
                    defaultAction: false,
                    on: self
                )
            }
        }
    }
}
