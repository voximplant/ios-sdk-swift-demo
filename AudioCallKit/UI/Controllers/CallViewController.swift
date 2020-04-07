/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK
import CallKit

class CallViewController: UIViewController, AppLifeCycleDelegate, TimerDelegate, KeyPadDelegate, VIAudioManagerDelegate, CXCallObserverDelegate {
    
    @IBOutlet weak var endpointDisplayNameLabel: EndpointLabel!
    @IBOutlet weak var keyPadView: KeyPadView!
    @IBOutlet weak var dtmfButton: ButtonWithLabel!
    @IBOutlet weak var muteButton: ButtonWithLabel!
    @IBOutlet weak var holdButton: ButtonWithLabel!
    @IBOutlet weak var speakerButton: ButtonWithLabel!
    @IBOutlet weak var callStateLabel: LabelWithTimer!
    
    private var userName: String?
    private var userDisplayName: String?
    private var callController: CXCallController = sharedCallController
    private var call: CXCall? { return callController.callObserver.calls.first }
    
    private var audioDevices: Set<VIAudioDevice>? {
        return VIAudioManager.shared().availableAudioDevices()
    }
    private var isMuted = false {
        willSet {
            muteButton.isSelected = newValue
            muteButton.label.text = newValue ? "unmute" : "mute"
        }
    }
    
    // MARK: - LifeCycle
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
            if let userName = endpoint?.user {
                self.userName = userName
            }
            if let userDisplayName = endpoint?.userDisplayName {
                self.userDisplayName = userDisplayName
            }
            endpointDisplayNameLabel.setUser(userDisplayName, userName)
            
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
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
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
                    AlertHelper.showError(message: error.localizedDescription)
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
        sender.isEnabled = false
        if let call = self.call {
            let setHeld = CXSetHeldCallAction(call: call.uuid, onHold: !sender.isSelected)
            callController.requestTransaction(with: setHeld)
            { [weak self] (error: Error?) in
                if let error = error {
                    Log.e("setHold error: \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription)
                    sender.isEnabled.toggle()
                } else {
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
            }
        }
    }
    
    @IBAction func hangupTouch(_ sender: UIButton) {
        Log.d("Call hangup called")
        sender.isEnabled = false
        if let call = self.call {
            // stop call if call exists
            let doEndCall = CXEndCallAction(call: call.uuid)
            callController.requestTransaction(with: doEndCall)
            { (error: Error?) in
                if let error = error {
                    AlertHelper.showError(message: error.localizedDescription)
                    Log.e(error.localizedDescription)
                }
                sender.isEnabled = true
            }
        }
    }
}

// MARK: CXCallObserverDelegate
extension CallViewController {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        updateContent()
        if call.hasEnded {
            Log.d("\(#function) called on \(String(describing: self))")
            performSegueIfPossible(withIdentifier: MainViewController.self, sender: self)
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
        guard let audioDevices = audioDevices else { return }
        let currentDevice = VIAudioManager.shared()?.currentAudioDevice()
        AlertHelper.showActionSheet(
            actions: audioDevices.map { device in
                UIAlertAction(title: makeFormattedString(from: device, isCurrent: currentDevice == device), style: .default) { _ in
                    VIAudioManager.shared().select(device)
                }
            },
            sourceView: speakerButton,
            on: self
        )
    }
    
    private func makeFormattedString(from device: VIAudioDevice, isCurrent: Bool) -> String {
        let formattedString = String(describing: device).replacingOccurrences(of: "VIAudioDevice", with: "")
        return isCurrent ? "\(formattedString) (Current)" : formattedString
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
                    AlertHelper.showError(message: error.localizedDescription)
                    Log.e(error.localizedDescription)
                }
            }
        }
    }
    
    func keypadDidHide() {
        // show the endpoint display name instead of DTMFs
        endpointDisplayNameLabel.setUser(userDisplayName, userName)
    }
}

// MARK: - TimerDelegate
extension CallViewController {
    func updateTime() {
        callStateLabel.updateCallStatus(call?.info?.duration())
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

typealias EndpointLabel = UILabel

fileprivate extension EndpointLabel {
    func setUser(_ userDisplayName: String?, _ userName: String?) {
        if let user = userDisplayName {
            self.text = user
        } else if let user = userName {
            self.text = user
        } else {
            self.text = "Calling..."
        }
    }
}
