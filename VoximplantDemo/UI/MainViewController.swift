/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK
import CocoaLumberjack
import MBProgressHUD

class MainViewController: BaseViewController {
    @IBOutlet var targetField: UITextField?
    @IBOutlet var audioCall: Button?
    @IBOutlet var videoCall: Button?
    var progress : MBProgressHUD?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = Settings.shared.displayName

        let backButton = UIBarButtonItem(title: "Logout".uppercased(), style: .plain, target: self, action: #selector(logoutTouched(sender:)))
        self.navigationItem.leftBarButtonItem = backButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let audio = self.audioCall, let video = self.videoCall {
            audio.isEnabled = true
            video.isEnabled = true
        }

        if let progress = self.progress {
            progress.hide(animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AppDelegate.instance().voxImplant!.checkPermissions()
    }

    @objc func logoutTouched(sender: AnyObject?) {
        AppDelegate.instance().voxImplant!.logout()
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func audioCallTouched(sender: AnyObject?) {
        self.startCall(withVideo: false)
    }

    @IBAction func videoCallTouched(sender: AnyObject?) {
        self.startCall(withVideo: true)
    }

    private func startCall(withVideo: Bool!) {
        if let contact = self.targetField?.text, contact.isEmpty {
            UIHelper.ShowError(error: "Contact login is empty")
            return
        }

        self.view.endEditing(true)

        if let audio = self.audioCall, let video = self.videoCall {
            audio.isEnabled = false
            video.isEnabled = false
            self.progress = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.progress?.label.text = "Calling"
            self.progress?.detailsLabel.text = "Please wait..."
        }

        let contact = self.targetField?.text!

        Log.d("Calling \(String(describing: contact)), with video: \(String(describing: withVideo))")

        let voxImplant = AppDelegate.instance().voxImplant!

        VIAudioManager.shared().select(VIAudioDevice(type: withVideo ? .speaker : .none))
        voxImplant.startOutgoingCall(contact, withVideo: withVideo)
    }

    override func voxDidLoggedOut(_ voximplant: VoxController!) {
        super.voxDidLoggedOut(voximplant)

        if let progress = self.progress {
            progress.hide(animated: true)
        }
    }

    override func voxDidLoggedIn(_ voximplant: VoxController!) {
        super.voxDidLoggedIn(voximplant)

        if let progress = self.progress {
            progress.hide(animated: true)
        }
    }

    override func vox(_ voximplant: VoxController!, prepared call: CallDescriptor!) {
        super.vox(voximplant, prepared: call)
    }

    override func vox(_ voximplant: VoxController!, ended call: CallDescriptor!, error: Error?) {
        super.vox(voximplant, ended: call, error: error)

        if let audio = self.audioCall, let video = self.videoCall {
            audio.isEnabled = true
            video.isEnabled = true

            if let progress = self.progress {
                progress.hide(animated: false)
            }
        }

        if let error = error {
            UIHelper.ShowError(error: error.localizedDescription)
        }
    }

    func reconnect() {
        if let vox = AppDelegate.instance().voxImplant?.client, vox.clientState != .loggedIn {
            self.progress = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.progress?.label.text = "Connecting"
            self.progress?.detailsLabel.text = "Please wait..."

            vox.connect()
        }
    }
}
