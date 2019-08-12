/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CallKit

class CallViewController: UIViewController, AppLifeCycleDelegate, TimerDelegate, KeyPadDelegate, VIAudioManagerDelegate, VICallDelegate {
    
    private var user: User? = nil
    
    private var audioDevices: Set<VIAudioDevice>? {
        return VIAudioManager.shared().availableAudioDevices()
    }

    private var authService: AuthService = sharedAuthService
    private var callController: CXCallController = sharedCallController
    private var call: CXCall? { //returns current call
        return callController.callObserver.calls.first
    }

    private var isMuted = false {
        willSet {
            muteButton.isSelected = newValue
            muteButton.label.text = newValue ? "unmute" : "mute"
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var endpointDisplayNameLabel: EndpointLabel!
    @IBOutlet weak var keyPadView: KeyPadView!
    @IBOutlet weak var dtmfButton: ButtonWithLabel!
    @IBOutlet weak var muteButton: ButtonWithLabel!
    @IBOutlet weak var holdButton: ButtonWithLabel!
    @IBOutlet weak var speakerButton: ButtonWithLabel!
    @IBOutlet weak var callStateLabel: LabelWithTimer!
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        VIAudioManager.shared().delegate = self
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }
    
    private func updateContent() {
        if let call = self.call,
           let callinfo = call.info
        {
            let endpoint = callinfo.endpoints.first
            switch (endpoint?.user, endpoint?.userDisplayName) {
            case let (fullUsername?, displayName?):
                self.user = User(fullUsername: fullUsername, displayName: displayName)
            case let (fullUsername?, nil):
                self.user = User(fullUsername: fullUsername, displayName: fullUsername)
            default:
                self.user = nil
            }
            endpointDisplayNameLabel.setUser(user)
            
            if call.hasConnected {
                dtmfButton.isEnabled = true // show call duration and unblock buttons
                holdButton.isEnabled = true
                callStateLabel.runTimer()
            } else {
                dtmfButton.isEnabled = false
                holdButton.isEnabled = false
            }
            
            if !call.isOnHold {
                holdButton.isSelected = false
                holdButton.label.text = "hold"
                holdButton.setImage(#imageLiteral(resourceName: "hold"), for: .normal)
            } else {
                holdButton.isSelected = true
                holdButton.label.text = "resume"
                holdButton.setImage(#imageLiteral(resourceName: "resumeP"), for: .normal)
            }
            
            self.isMuted = !callinfo.sendAudio
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: Actions
    @IBAction func muteTouch(_ sender: UIButton) {
        Log.d("Changing mute state")
        if let call = self.call {
            isMuted.toggle()
            let setMute = CXSetMutedCallAction(call: call.uuid, muted: isMuted)
            callController.requestTransaction(with: setMute)
            { (error: Error?) in
                if let error = error {
                    Log.e(error.localizedDescription)
                    UIHelper.ShowError(error: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func dtmfTouch(_ sender: UIButton) {
        endpointDisplayNameLabel.text = " " //clear label to show DTMFs
        keyPadView.isHidden = false //show keypad
    }
    
    @IBAction func audioDeviceTouch(_ sender: UIButton) {
        showAudioDevices()
    }
    
    @IBAction func holdTouch(_ sender: UIButton) {
        if let call = self.call {
            let setHeld = CXSetHeldCallAction(call: call.uuid, onHold: !sender.isSelected)
            callController.requestTransaction(with: setHeld)
            { [weak self] (error: Error?) in
                if let error = error {
                    Log.e("setHold error: \(error.localizedDescription)")
                    UIHelper.ShowError(error: error.localizedDescription)
                } else {
                    if sender.isSelected {
                        self?.holdButton.label.text = "hold"
                        sender.setImage(#imageLiteral(resourceName: "hold"), for: .normal)
                    } else {
                        self?.holdButton.label.text = "resume"
                        sender.setImage(#imageLiteral(resourceName: "resumeP"), for: .normal)
                    }
                    sender.isSelected.toggle()
                }
            }
        }
    }
    
    @IBAction func hangupTouch(_ sender: UIButton) {
        Log.d("Call hangup called")
        if let call = self.call {
            // stop call if call exists
            let doEndCall = CXEndCallAction(call: call.uuid)
            callController.requestTransaction(with: doEndCall)
            { (error: Error?) in
                if let error = error {
                    UIHelper.ShowError(error: error.localizedDescription)
                    Log.e(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: CXCallObserverDelegate
extension CallViewController: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        
        updateContent()
        
        if call.hasEnded {
            Log.d("\(#function) called on \(String(describing: self))")
            performSegue(withIdentifier: MainViewController.self, sender: self)
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
    
    private func generateDeviceTitle(_ device: VIAudioDevice) -> String { // generates fromatted string from VIAudioDevice names
        let deviceString = String(describing: device)
        let clearDeviceName = deviceString.replacingOccurrences(of: "VIAudioDevice", with: "")
        return clearDeviceName
    }
    
    private func changeAudioDeviceButtonState(isSelected: Bool, image: UIImage) {
        speakerButton.setImage(image, for: .selected)
        speakerButton.isSelected = isSelected
    }
}

// MARK: AppLifeCycleDelegate
extension CallViewController {
    func applicationDidBecomeActive(_ application: UIApplication) {
        updateContent()
    }
}

// MARK: KeypadDelegate
extension CallViewController {
    func DTMFButtonTouched(symbol: String) {
        Log.d("DTMF code: \(symbol)")
        // replace the endpoint display name with DTMFs sent
        endpointDisplayNameLabel.text! += symbol
        if let call = self.call {
            let sendDTMF = CXPlayDTMFCallAction(call: call.uuid, digits: symbol, type: .singleTone)
            callController.requestTransaction(with: sendDTMF)
            { (error: Error?) in
                if let error = error {
                    UIHelper.ShowError(error: error.localizedDescription)
                    Log.e(error.localizedDescription)
                }
            }
        }
    }
    
    func keypadDidHide() {
        // show the endpoint display name instead of DTMFs
        endpointDisplayNameLabel.setUser(user)
    }
}

// MARK: TimerDelegate
extension CallViewController {
    func updateTime() {
        callStateLabel.setTime(call?.info?.duration())
    }
}

fileprivate extension LabelWithTimer {
    func setTime(_ time: TimeInterval?) {
        let text: String
        if let time = time {
            text = time.toString() + " - "
        } else {
            text = ""
        }
        self.text = text + "Call in progress"
    }
}

fileprivate extension TimeInterval {
    // mm:ss format
    func toString() -> String {
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
}

typealias EndpointLabel = UILabel

fileprivate extension EndpointLabel {
    func setUser(_ user: User?) {
        if let user = user {
            if user.displayName != "" {
                self.text = user.displayName
            } else {
                self.text = user.fullUsername
            }
        } else {
            self.text = "Calling"
        }
    }
}
