/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class CallFailedViewController: UIViewController, CallManagerDelegate {
    
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    @IBOutlet weak var failReason: UILabel!
    
    var callFailedInfo: (username: String, reasonToFail: String)!  // this piece of code receives info from CallVC to update labels on CallFailedVC.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        failReason.text = callFailedInfo.reasonToFail
        endpointDisplayNameLabel.text = callFailedInfo.username
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
    }
    
    // MARK: CallManagerDelegate
    func notifyIncomingCall(_ descriptor: VICall) {
        self.performSegue(withIdentifier: MainViewController.self, sender: self)
    }
}
