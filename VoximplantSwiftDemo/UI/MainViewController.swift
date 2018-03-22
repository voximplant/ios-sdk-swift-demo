/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CocoaLumberjack

class MainViewController: BaseViewController {
    @IBOutlet var targetField: UITextField?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.title = Settings.shared.displayName

        let backButton = UIBarButtonItem(title: "Logout".uppercased(), style: .plain, target: self, action: #selector(logoutTouched(sender:)))
        self.navigationItem.leftBarButtonItem = backButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AppDelegate.instance().voxImplant!.checkPermissions()
    }

    @objc func logoutTouched(sender: AnyObject?) {
        AppDelegate.instance().voxImplant!.logout()
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

        let contact = self.targetField?.text!

        Log.d("Calling \(String(describing: contact)), with video: \(withVideo)")

        let voxImplant = AppDelegate.instance().voxImplant!

        VIAudioManager.shared().select(VIAudioDevice(type: withVideo ? .speaker : .none))
        voxImplant.startOutgoingCall(contact, withVideo: withVideo)
    }

    override func voxDidLoggedOut(_ voximplant: VoxController!) {
        super.voxDidLoggedOut(voximplant)

        self.navigationController?.popViewController(animated: true)
    }

    override func vox(_ voximplant: VoxController!, prepared call: CallDescriptor!) {
        super.vox(voximplant, prepared: call)

    }
}
