/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class MainViewController:
    UIViewController,
    AppLifeCycleDelegate,
    LoadingShowable,
    ErrorHandling
{
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    @IBOutlet private var mainView: DefaultMainView!
    
    var authService: AuthService! // DI
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let displayName = authService.loggedInUserDisplayName {
            mainView.setDisplayName(text: "Logged in as \(displayName)")
        }
        
        mainView.callTouchHandler = { [weak self] username in
            Log.d("Calling \(String(describing: username))")            
            PermissionsHelper.requestRecordPermissions { error in
                if let error = error {
                    self?.handleError(error)
                    return
                }
                
                guard let self = self else { return }
                
                let beginCall = {
                    do {
                        try self.callManager.makeOutgoingCall(to: username ?? "")
                        self.view.endEditing(true)
                        self.present(AnimatedTransitionNavigationController(
                            rootViewController: self.storyAssembler.call), animated: true)
                    } catch (let error) {
                        Log.e(error.localizedDescription)
                        AlertHelper.showError(message: error.localizedDescription, on: self)
                    }
                }
                
                if !self.authService.isLoggedIn {
                    self.reconnect(onSuccess: beginCall)
                } else {
                    beginCall()
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
        
        callManager.didReceiveIncomingCall = { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.present(AnimatedTransitionNavigationController(
                rootViewController: self.storyAssembler.incomingCall), animated: true)
        }
    }
    
    deinit {
        callManager.didReceiveIncomingCall = nil
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
                        UIAlertAction(title: "Logout", style: .destructive) { _ in
                            self.authService.logout {
                                self.dismiss(animated: true)
                            }
                        },
                    ],
                    defaultAction: false)
            } else {
                onSuccess?()
            }
        }
    }
}
