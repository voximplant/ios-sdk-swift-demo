/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class CallFailedViewController: UIViewController, CallManagerDelegate {
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    @IBOutlet weak var failReason: UILabel!
    
    var callFailedInfo: (username: String, reasonToFail: String)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        failReason.text = callFailedInfo.reasonToFail
        endpointDisplayNameLabel.text = callFailedInfo.username
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
    }
    
    // MARK: - CallManagerDelegate -
    func notifyIncomingCall(_ descriptor: VICall) {
        self.performSegue(withIdentifier: MainViewController.self, sender: self)
    }
}
