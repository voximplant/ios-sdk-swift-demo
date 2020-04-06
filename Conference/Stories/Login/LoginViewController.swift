/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LoginViewController: UIViewController {
    @IBOutlet private var loginView: LoginView!
    
    var joinConference: JoinConference! // DI
    
    private let previousNameKey = "previousName"
    private var previousName: String? {
        get { UserDefaults.standard.value(forKey: previousNameKey) as? String }
        set { UserDefaults.standard.setValue(newValue, forKey: previousNameKey) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginView.setupView()
        if let name = previousName { loginView.showLatestUsername(name) }
    }
    
    @IBAction private func joinVideoTouchUp(_ sender: UIButton) {
        loginView.hideKeyboard()
        join(withVideo: true)
    }
    
    @IBAction private func joinAudioTouchUp(_ sender: UIButton) {
        loginView.hideKeyboard()
        join(withVideo: false)
    }
    
    private func join(withVideo video: Bool) {
        guard let id = loginView.idText,
            let name = loginView.nameText
            else {
                AlertHelper.showError(message: "Fields must not be empty", on: self)
                return
        }
        
        loginView.state = .loading
        
        joinConference.execute(withId: id, andName: name, sendVideo: video) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loginView.state = .normal
                if let error = error {
                    self.handle(error: error)
                } else {
                    self.previousName = name
                    self.present(StoryAssembler.assembleConferenceCall(name: name, video: video), animated: true)
                }
            }
        }
    }
    
    private func handle(error: Error) {
        if case Errors.audioPermissionsDenied = error {
            AlertHelper.showError(message: "Audio permissions needed", action: accessSettingsAction, on: self)
        } else if case Errors.videoPermissionsDenied = error {
            AlertHelper.showError(message: "Video permissions needed", action: accessSettingsAction, on: self)
        } else {
            AlertHelper.showError(message: error.localizedDescription, on: self)
        }
    }
    
    private var accessSettingsAction: UIAlertAction {
        UIAlertAction(title: "Open settings", style: .default) { _ in
            let settings = URL(string: UIApplication.openSettingsURLString)!
            if #available(iOS 10.0, *) { UIApplication.shared.open(settings) }
            else { UIApplication.shared.openURL(settings) }
        }
    }
}
