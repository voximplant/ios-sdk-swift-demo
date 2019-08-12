/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

class CallViewController: UIViewController, TimerDelegate, KeyPadDelegate, VIAudioManagerDelegate, VICallDelegate {
    
    private var endpoint = User("","")
    private var callFailedInfo: (username: String, reasonToFail: String)? // this piece of code sends info to CallFailedVC after callDidFail.
    private var audioDevices: Set<VIAudioDevice>? {
        return VIAudioManager.shared().availableAudioDevices()
    }
    private var call: VICall? {
        return callManager.managedCall
    }
    private let callManager: CallManager = sharedCallManager
    private var authService: AuthService = sharedAuthService
    private var isMuted = false {
        willSet {
            muteButton.isSelected = newValue
            muteButton.label.text = newValue ? "unmute" : "mute"
            call?.sendAudio = !newValue
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var endpointDisplayNameLabel: UILabel! //shows endpoint name
    @IBOutlet weak var keyPadView: KeyPadView! //hidden view with dtmf buttons
    @IBOutlet weak var dtmfButton: ButtonWithLabel! //button used to show dtmf view
    @IBOutlet weak var muteButton: ButtonWithLabel!
    @IBOutlet weak var holdButton: ButtonWithLabel! //button used to hold and resume call
    @IBOutlet weak var speakerButton: ButtonWithLabel!
    @IBOutlet weak var callStateLabel: LabelWithTimer! //shows current call state and in-call time
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endpoint.fullUsername = callManager.managedCall!.endpoints.first!.user!
        endpointDisplayNameLabel.text = endpoint.fullUsername
        setupDelegates()
    }
    
    // MARK: Setup
    private func setupDelegates() {
        call?.add(self) //used to work with call events
        VIAudioManager.shared().delegate = self //used to work with audio devices events
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: Actions
    @IBAction func muteTouch(_ sender: UIButton) {
        Log.d("Changing mute state")
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
        sender.isEnabled = false
        
        call?.setHold(!sender.isSelected, completion: { [weak self] error in
            if error == nil {
                Log.d("setHold: no errors)")
                
                if sender.isSelected {
                    self?.holdButton.label.text = "hold"
                    sender.setImage(#imageLiteral(resourceName: "hold"), for: .normal)
                } else {
                    self?.holdButton.label.text = "resume"
                    sender.setImage(#imageLiteral(resourceName: "resumeP"), for: .normal)
                }
                
                sender.isSelected.toggle()
                sender.isEnabled.toggle()
            } else {
                Log.d("setHold: \(error!.localizedDescription)")
                UIHelper.ShowError(error: error!.localizedDescription)
                sender.isEnabled.toggle()
            }
        })
    }
    
    @IBAction func hangupTouch(_ sender: UIButton) {
        Log.d("Call hangup called");
        call?.hangup(withHeaders: nil) // stop call if call exists
    }
    
    // MARK: Call failed segues
    @IBAction func unwindWithCallBack(segue: UIStoryboardSegue) { //this method triggered if user tapped on CallBack from Fail Screen
        Log.d("Calling \(String(describing: callFailedInfo!.username))")
        
        callManager.startOutgoingCall(callFailedInfo!.username) {
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
            guard let infoAboutFail = callFailedInfo else { return }
            controller.callFailedInfo = infoAboutFail
        }
        
        call?.remove(self)
    }
    
}

// MARK: VICallDelegate
extension CallViewController {
    func call(_ call: VICall, startRingingWithHeaders headers: [AnyHashable : Any]?) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        callStateLabel.text = "Ringing..."
    }
    
    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable : Any]?) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        if let username = call.endpoints.first?.user,
            let displayName = call.endpoints.first?.userDisplayName {
            endpoint.fullUsername = username
            endpoint.displayName = displayName
        }
        
        endpointDisplayNameLabel.text = endpoint.displayName
        dtmfButton.isEnabled = true // show call duration and unblock buttons
        holdButton.isEnabled = true
        
        callStateLabel.runTimer()
    }
    
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable : Any]?, answeredElsewhere: NSNumber) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        self.call?.remove(self)
        
        performSegue(withIdentifier: MainViewController.self, sender: self)
    }
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        Log.d("\(#function) called on \(String(describing: self))")
        
        self.call?.remove(self)
        
        if (error as NSError).code == VICallFailError.invalidNumber.rawValue {
            self.dismiss(animated: false) {
                UIHelper.ShowError(error: error.localizedDescription)
            }
        } else {
            callFailedInfo = (call.endpoints.first!.user!, error.localizedDescription)
            performSegue(withIdentifier: CallFailedViewController.self, sender: self)
        }
    }
}

// MARK: VIAudioManagerDelegate
extension CallViewController {
    
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
        let clearDeviceName = deviceString.replacingOccurrences(of: "VIAudioDevice", with: "")
        return clearDeviceName
    }
    
    // This method changes speaker button states given by audiodevice delegate
    private func changeAudioDeviceButtonState(isSelected: Bool, image: UIImage) {
        speakerButton.setImage(image, for: .selected)
        speakerButton.isSelected = isSelected
    }
}

// MARK: KeyPadDelegate
extension CallViewController {
    func DTMFButtonTouched(symbol: String) {
        Log.d("DTMF code: \(symbol)")
        endpointDisplayNameLabel.text! += symbol // saves all buttons touched in dtmf to label instead of endpoint name
        call?.sendDTMF(symbol) // sending dtmf to sdk
    }
    
    func keypadDidHide() {
        endpointDisplayNameLabel.text = endpoint.displayName // if dtmf keyboard been closed - show endpoint name instead of numbers
    }
}

// Work with Timer happens here
// MARK: TimerDelegate
extension CallViewController {
    func updateTime() {
        let time: String
        if let timeString: String = call?.duration().toString() {
            time = timeString + " - "
        } else {
            time = ""
        }
        callStateLabel.text = time + "Call in progress"
    }
}

fileprivate extension TimeInterval { // used to convert timeinterval to string
    func toString() -> String { // converting time interval to mm:ss
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
}
