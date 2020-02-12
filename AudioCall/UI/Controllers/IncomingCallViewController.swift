/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class IncomingCallViewController: UIViewController, VICallDelegate {

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
        
        call?.add(self) // add call delegate to current call
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        endpointDisplayNameLabel.text = call?.endpoints.first?.userDisplayName
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        call?.remove(self)
    }
    
    // MARK: Actions
    @IBAction func declineTouch(_ sender: UIButton) {
        Log.d("Rejecting call")
        call?.reject(with: .decline, headers: nil) // decline call
    }
    
    @IBAction func acceptTouch(_ sender: UIButton) {
        PermissionsManager.checkAudioPermisson {
            Log.d("Accepting call")
            self.callManager.makeIncomingCallActive() // answer call
            self.call?.remove(self)
            self.performSegue(withIdentifier: CallViewController.self, sender: self)
        }
    }
    
}

// MARK: VICall Delegate
extension IncomingCallViewController {
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
  
        
        self.call?.remove(self)
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        
        self.call?.remove(self)
        
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
}

// MARK: CallManagerDelegate default behaviour
extension CallManagerDelegate where Self: UIViewController {
    func notifyIncomingCall(_ descriptor: VICall) {
        self.performSegueIfPossible(withIdentifier: IncomingCallViewController.self, sender: self)
    }
}
