/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class IncomingCallViewController: UIViewController {

    // MARK: Properties
    private let callManager: CallManager = sharedCallManager
    private var call: VICall? {
        return callManager.managedCall
    }
    
    // MARK: Outlets
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        call?.add(self) //used to work with call events
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        changeStatusBarStyle(to: .default)
        endpointDisplayNameLabel.text = call?.endpoints.first?.userDisplayName
    }
    
        
    // MARK: Actions
    @IBAction func declineTouch(_ sender: UIButton) {
        call?.reject(with: .decline, headers: nil) // stop call
    }
    
    
    @IBAction func acceptTouch(_ sender: UIButton) {
        callManager.makeIncomingCallActive()
    }
    
}

extension IncomingCallViewController: VICallDelegate {
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        if let activeAlertController = self.presentedViewController as? UIAlertController {
            activeAlertController.dismiss(animated: false, completion: nil)
        }
        
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
}
