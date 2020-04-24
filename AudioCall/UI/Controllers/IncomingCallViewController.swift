/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class IncomingCallViewController: UIViewController, VICallDelegate, ErrorHandling {
    private let callManager: CallManager = sharedCallManager
    private var call: VICall? { callManager.managedCall }
    
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        call?.add(self)
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
    
    @IBAction func declineTouch(_ sender: UIButton) {
        Log.d("Rejecting call")
        call?.reject(with: .decline, headers: nil)
    }
    
    @IBAction func acceptTouch(_ sender: UIButton) {
        PermissionsHelper.requestRecordPermissions(includingVideo: false) { error in
            if let error = error { self.handleError(error) } else {
                Log.d("Accepting call")
                self.callManager.makeIncomingCallActive() // answer call
                self.call?.remove(self)
                self.performSegue(withIdentifier: CallViewController.self, sender: self)
            }
        }
    }
    
    // MARK: - VICallDelegate -
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
