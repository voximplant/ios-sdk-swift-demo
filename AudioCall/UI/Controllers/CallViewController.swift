/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class CallViewController: UIViewController {
    
    // MARK: Properies
    private var endpointDisplayName: String { //used to show displayname on the screen
        get {
            return callManager.managedCall?.endpoints.first?.userDisplayName ?? endpointUsername
        }
        set {
             endpointDisplayNameLabel.text = newValue
        }
    }
    var endpointUsername: String = "" //saving this parameter allows us to recall later
    private var audioDevices: Set<VIAudioDevice>? {
        return VIAudioManager.shared().availableAudioDevices()
    }
    private var call: VICall? { //returns current call
        return callManager.managedCall
    }
    private let callManager: CallManager = sharedCallManager
    private var authService: AuthService = sharedAuthService
    private var reasonToFail: String? {
        didSet {
            performSegue(withIdentifier: CallFailedViewController.self, sender: self)
        }
    }
    private var isMuted = false {
        willSet {
            muteButton.isSelected = newValue
            muteLabel.text = newValue ? "unmute" : "mute"
            call?.sendAudio = !newValue
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var endpointDisplayNameLabel: UILabel! //shows endpoint name
    @IBOutlet weak var keyPadView: KeyPadView! //hidden view with dtmf buttons
    @IBOutlet weak var dtmfButton: UIButton! //button used to show dtmf view
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var muteLabel: UILabel! //label used to show if mic is muted
    @IBOutlet weak var holdButton: UIButton! //button used to hold and resume call
    @IBOutlet weak var holdLabel: UILabel! //label used to show if call is on hold
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var callStateLabel: LabelWithTimer! //shows current call state and in-call time
    
    // MARK: LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupDelegates()
        setupUI()
    }
    
    // MARK: Setup
    private func setupDelegates() {
        call?.add(self) //used to work with call events
        VIAudioManager.shared().delegate = self //used to work with audio devices events
    }
    
    private func setupUI() {
        endpointDisplayNameLabel.text = endpointDisplayName
        changeStatusBarStyle(to: .default)
    }
    
    // MARK: Actions
    @IBAction func muteTouch(_ sender: UIButton) {
        isMuted.toggle() //changes mute state
    }
    
    @IBAction func dtmfTouch(_ sender: UIButton) {
        endpointDisplayNameLabel.text = " " //clear label to show numbers
        keyPadView.isHidden = false //show keypad
    }
    
    @IBAction func audioDeviceTouch(_ sender: UIButton) {
        showAudioDevices()
    }
    
    @IBAction func holdTouch(_ sender: UIButton) {
        call?.setHold(!sender.isSelected, completion: { error in // sets call hold to true/false depending on button state
            
            guard let error = error else {
                Log.d("setHold: no errors)")
                
                if sender.isSelected {
                    self.holdLabel.text = "hold"
                    sender.setImage(#imageLiteral(resourceName: "hold"), for: .normal)
                } else {
                    self.holdLabel.text = "resume"
                    sender.setImage(#imageLiteral(resourceName: "resumeP"), for: .normal)
                }
                
                sender.isSelected.toggle()
                
                return
            }
            
            Log.d("setHold: \(error.localizedDescription)")
            UIHelper.ShowError(error: error.localizedDescription)
        })
    }
    
    @IBAction func hangupTouch(_ sender: UIButton) {
        call?.hangup(withHeaders: nil) // stop call if call exists
    }
    
    // MARK: Call failed segues
    @IBAction func unwindWithCallBack(segue: UIStoryboardSegue) { //this method triggered if user tapped on CallBack from Fail Screen
        Log.d("Calling \(String(describing: endpointUsername))")
        
        callManager.startOutgoingCall(endpointUsername) {
            (result: Result<(), Error>) in
            if case let .failure(error) = result {
                self.dismiss(animated: false) {
                    UIHelper.ShowError(error: error.localizedDescription)
                }
            } else {
                self.setupDelegates()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CallFailedViewController {
            controller.endpointDisplayName = endpointDisplayName
            controller.failingReason = reasonToFail
        }
    }
    
}

// MARK: Call Delegate
extension CallViewController: VICallDelegate {
    func call(_ call: VICall, startRingingWithHeaders headers: [AnyHashable : Any]?) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        callStateLabel.text = "Ringing..."
    }
    
    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable : Any]?) {
        Log.d("\(#function) called on \(String(describing: self))")
        endpointUsername = callManager.managedCall?.endpoints.first?.user ?? ""
        
        dtmfButton.isEnabled = true // show call duration and unblock buttons
        holdButton.isEnabled = true
        
        callStateLabel.runTimer()
    }
    
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        if (error as NSError).code == VICallFailError.invalidNumber.rawValue {
            self.dismiss(animated: false) {
                UIHelper.ShowError(error: error.localizedDescription)
            }
        } else {
            reasonToFail = error.localizedDescription
        }
    }
}

// MARK: Audio Manager Delegate
extension CallViewController: VIAudioManagerDelegate {
    
    func audioDeviceChanged(_ audioDevice: VIAudioDevice!) {
        Log.v("audioDeviceBecomeDefault: \(String(describing: audioDevice))")
        
        switch audioDevice.type {
        case .none:
            changeAudioDeviceButtonState(isSelected: false, image: #imageLiteral(resourceName: "speakerP"))
        case .receiver:
            changeAudioDeviceButtonState(isSelected: false, image: #imageLiteral(resourceName: "speakerP"))
        case .speaker:
            changeAudioDeviceButtonState(isSelected: true, image: #imageLiteral(resourceName: "speakerP"))
        case .wired:
            changeAudioDeviceButtonState(isSelected: true, image: #imageLiteral(resourceName: "speakerW"))
        case .bluetooth:
            changeAudioDeviceButtonState(isSelected: true, image: #imageLiteral(resourceName: "speakerBT"))
        @unknown default:
            changeAudioDeviceButtonState(isSelected: false, image: #imageLiteral(resourceName: "speakerP"))
        }
    }
    
    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice!) {
        Log.v("audioDeviceUnavailable: \(String(describing: audioDevice))")
    }
    
    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>!) {
        Log.v("audioDevicesListChanged: \(String(describing: availableAudioDevices))")
    }
    
    // MARK: AudioManager supporting methods
    // This method used to show/hide audio devices list
    private func showAudioDevices() {
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for device in audioDevices! {
            alertSheet.addAction(UIAlertAction(title: generateDeviceTitle(device), style: .default) { action in
                VIAudioManager.shared().select(device)
            })
        }
        
        alertSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            alertSheet.dismiss(animated: true, completion: nil)
        }))
        
        present(alertSheet, animated: true, completion: nil) // show alertsheet with audio devices
    }
    
    // This method used to generate clear device name from VIAudioDevice
    private func generateDeviceTitle(_ device: VIAudioDevice) -> String { // generates fromatted string from VIAudioDevice names
        let deviceString = String(describing: device)
        let clearDeviceName = deviceString.replacingOccurrences(of: "VIAudioDevice",
                                                                with: "")
        return clearDeviceName
    }
    
    // This method changes speaker button states given by audiodevice delegate
    private func changeAudioDeviceButtonState(isSelected: Bool, image: UIImage) {
        speakerButton.setImage(image, for: .selected)
        speakerButton.isSelected = isSelected
    }
}

// MARK: Keypad Delegate
extension CallViewController: KeyPadDelegate {
    func DTMFButtonTouched(symbol: String) {
        Log.d("DTMF code: \(symbol)")
        endpointDisplayNameLabel.text! += symbol // saves all buttons touched in dtmf to label instead of endpoint name
        call?.sendDTMF(symbol) // sending dtmf to sdk
    }
    
    func keypadDidHide() {
        endpointDisplayNameLabel.text = endpointDisplayName // if dtmf keyboard been closed - show endpoint name instead of numbers
    }
}

// MARK: Work with Timer happens here
extension CallViewController: TimerDelegate {
    func updateTime() {
        callStateLabel.text = "\(timeString(time: call?.duration())) - Call in progress"
    }
}


