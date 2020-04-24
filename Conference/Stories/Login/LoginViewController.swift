/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LoginViewController: UIViewController, ErrorHandling {
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
                    self.handleError(error)
                } else {
                    self.previousName = name
                    self.present(StoryAssembler.assembleConferenceCall(name: name, video: video), animated: true)
                }
            }
        }
    }
}
