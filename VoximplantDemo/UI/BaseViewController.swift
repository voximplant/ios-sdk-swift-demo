/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import CocoaLumberjack
import VoxImplantSDK

class BaseViewController: UIViewController, VoxControllerDelegate {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppDelegate.instance().voxImplant!.delegate = self
    }

    func voxDidLoggedIn(_ voximplant: VoxController!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func voxDidLoggedOut(_ voximplant: VoxController!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func vox(_ voximplant: VoxController!, prepared call: CallDescriptor!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func vox(_ voximplant: VoxController!, started call: CallDescriptor!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func vox(_ voximplant: VoxController!, ended call: CallDescriptor!, error: Error?) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func vox(_ voximplant: VoxController!, call: CallDescriptor!, didAdd endpoint: VIEndpoint!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func vox(_ voximplant: VoxController!, startRinging call: CallDescriptor!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }

    func vox(_ voximplant: VoxController!, stopRinging call: CallDescriptor!) {
        Log.d("\(#function) called on \(String(describing: self))")
    }
}

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask     {
        return .all
    }
}
