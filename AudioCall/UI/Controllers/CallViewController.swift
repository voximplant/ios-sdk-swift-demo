/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class CallViewController:
    UIViewController,
    TimerDelegate,
    KeyPadDelegate,
    VIAudioManagerDelegate,
    VICallDelegate,
    AudioDeviceSelecting
{
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    @IBOutlet weak var keyPadView: KeyPadView!
    @IBOutlet weak var dtmfButton: ButtonWithLabel!
    @IBOutlet weak var muteButton: ButtonWithLabel!
    @IBOutlet weak var holdButton: ButtonWithLabel!
    @IBOutlet weak var speakerButton: ButtonWithLabel!
    @IBOutlet weak var callStateLabel: LabelWithTimer!
    
    private var userName: String?
    private var userDisplayName: String?
    private var callFailedInfo: (username: String, reasonToFail: String)?
    private let callManager: CallManager = sharedCallManager
    private var authService: AuthService = sharedAuthService
    private var call: VICall? { callManager.managedCall }
    private var isMuted = false {
        willSet {
            muteButton.isSelected = newValue
            muteButton.label.text = newValue ? "unmute" : "mute"
            call?.sendAudio = !newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VIAudioManager.shared().delegate = self
        call?.add(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEndpointLabel()
    }
    
    private func updateEndpointLabel() {
        if let endpoint = call?.endpoints.first {
            endpointDisplayNameLabel.text = endpoint.userDisplayName != nil
                ? endpoint.userDisplayName : endpoint.user
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
    }
    
    @IBAction func muteTouch(_ sender: UIButton) {
        Log.d("Changing mute state")
        isMuted.toggle() //changes mute state
    }
    
    @IBAction func dtmfTouch(_ sender: UIButton) {
        endpointDisplayNameLabel.text = " " //clear label to show numbers
        keyPadView.isHidden = false //show keypad
    }
    
    @IBAction func audioDeviceTouch(_ sender: UIButton) {
        Log.d("Showing audio devices actionSheet")
        showAudioDevicesActionSheet(sourceView: sender)
    }
    
    @IBAction func holdTouch(_ sender: UIButton) {
        sender.isEnabled = false
        
        call?.setHold(!sender.isSelected, completion: { [weak self] error in
            if let error = error {
                Log.d("setHold: \(error.localizedDescription)")
                AlertHelper.showError(message: error.localizedDescription, on: self)
                sender.isEnabled.toggle()
            } else {
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
            }
        })
    }
    
    @IBAction func hangupTouch(_ sender: UIButton) {
        Log.d("Call hangup called");
        call?.hangup(withHeaders: nil)
    }
    
    // MARK: Call failed segues
    @IBAction func unwindWithCallBack(segue: UIStoryboardSegue) {
        Log.d("Calling \(String(describing: callFailedInfo!.username))")
        
        callManager.startOutgoingCall(callFailedInfo!.username) {
            (result: Result<(), Error>) in
            if case let .failure(error) = result {
                self.dismiss(animated: false) {
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                }
            } else {
                self.call?.add(self)
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
        
        updateEndpointLabel()
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
                AlertHelper.showError(message: error.localizedDescription, on: self)
            }
        } else {
            callFailedInfo = (call.endpoints.first?.user ?? "unknown", error.localizedDescription)
            performSegue(withIdentifier: CallFailedViewController.self, sender: self)
        }
    }
    
    // MARK: - VIAudioManagerDelegate -
    func audioDeviceChanged(_ audioDevice: VIAudioDevice) {
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
    
    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice) {
        Log.v("audioDeviceUnavailable: \(String(describing: audioDevice))")
    }
    
    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>) {
        Log.v("audioDevicesListChanged: \(String(describing: availableAudioDevices))")
    }

    private func changeAudioDeviceButtonState(isSelected: Bool, image: UIImage) {
        speakerButton.setImage(image, for: .selected)
        speakerButton.isSelected = isSelected
    }
    
    // MARK: - KeyPadDelegate -
    func DTMFButtonTouched(symbol: String) {
        Log.d("DTMF code: \(symbol)")
        endpointDisplayNameLabel.text! += symbol
        call?.sendDTMF(symbol)
    }
    
    func keypadDidHide() {
        updateEndpointLabel()
    }
    
    // MARK: - TimerDelegate -
    func updateTime() {
        callStateLabel.updateCallStatus(call?.duration())
    }
}


fileprivate extension LabelWithTimer {
    func updateCallStatus(_ time: TimeInterval?) {
        if let timeInterval = time {
            let text = self.buildStringTimeToDisplay(timeInterval: timeInterval)
            self.text = "\(text) - Call in progress"
        } else {
            self.text = "Call in progress"
        }
    }
}
