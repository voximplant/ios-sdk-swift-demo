/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class CallFailedViewController:
    UIViewController,
    LoadingShowable,
    AppLifeCycleDelegate
{
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    @IBOutlet private var callFailedView: DefaultCallFailedView!
    
    var authService: AuthService! // DI
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    var failReason: String! // DI
    var user: String! // DI
    var displayName: String! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callFailedView.displayName = displayName
        callFailedView.reason = failReason
        
        callManager.didReceiveIncomingCall = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.setViewControllers(
                [self.storyAssembler.incomingCall],
                animated: true
            )
        }
        
        callFailedView.cancelHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        callFailedView.callBackHandler = { [weak self] in
            guard let self = self else { return }
            let beginCall = {
                do {
                    try self.callManager.makeOutgoingCall(to: self.user)
                    self.navigationController?.setViewControllers(
                        [self.storyAssembler.call],
                        animated: true
                    )
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
            
            if !self.authService.isLoggedIn {
                self.reconnect(onSuccess: beginCall)
            } else {
                beginCall()
            }
        }
    }
    
    // MARK: - AppLifeCycleDelegate -
    func applicationDidBecomeActive(_ application: UIApplication) {
        if (!authService.isLoggedIn) {
            reconnect()
        }
    }
    
    // MARK: - Private -
    private func reconnect(onSuccess: (() -> Void)? = nil) {
        Log.d("Reconnecting")
        showLoading(title: "Reconnecting", details: "Please wait...")
        authService.loginWithAccessToken { [weak self] error in
            guard let self = self else { return }
            self.hideProgress()
            
            if let error = error {
                AlertHelper.showAlert(
                    title: "Connection error",
                    message: error.localizedDescription,
                    actions: [
                        UIAlertAction(title: "Try again", style: .default) { _ in
                            self.reconnect()
                        },
                    ],
                    defaultAction: true)
            } else {
                onSuccess?()
            }
        }
    }
}
