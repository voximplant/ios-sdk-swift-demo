/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK
import CallKit

final class CallViewController:
    UIViewController,
    AppLifeCycleDelegate,
    AudioDeviceAlertSelecting,
    VIAudioManagerDelegate,
    CallReconnectDelegate,
    CXCallObserverDelegate
{
    @IBOutlet weak var endpointDisplayNameLabel: EndpointLabel!
    @IBOutlet weak var keyPadView: KeyPadView!
    @IBOutlet weak var dtmfButton: ButtonWithLabel!
    @IBOutlet weak var muteButton: ButtonWithLabel!
    @IBOutlet weak var holdButton: ButtonWithLabel!
    @IBOutlet weak var speakerButton: ButtonWithLabel!
    @IBOutlet weak var callStateLabel: LabelWithTimer!
    
    private var userName: String?
    private var userDisplayName: String?
    private let callController: CXCallController = sharedCallController
    private var call: CXCall? { callController.callObserver.calls.first }
    private var reconnecting = false
    private var isMuted = false {
        willSet {
            muteButton.isSelected = newValue
            muteButton.label.text = newValue ? "unmute" : "mute"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyPadView.DTMFHandler = { [weak self] symbol in
            Log.d("DTMF code: \(symbol)")
            guard let self = self else { return }
            // replace the endpoint display name with DTMFs sent
            self.endpointDisplayNameLabel.text? += symbol
            if let call = self.call {
                let sendDTMF = CXPlayDTMFCallAction(
                    call: call.uuid,
                    digits: symbol,
                    type: .singleTone
                )
                self.callController.requestTransaction(with: sendDTMF) { error in
                    if let error = error {
                        AlertHelper.showError(message: error.localizedDescription, on: self)
                        Log.e(error.localizedDescription)
                    }
                }
            }
        }
        
        keyPadView.hideHandler = { [weak self] in
            guard let self = self else { return }
            // show the endpoint display name instead of DTMFs
            self.endpointDisplayNameLabel.setUser(self.userDisplayName, self.userName)
            self.keyPadView.isHidden = true
        }
        
        sharedCallManager.reconnectDelegate = self
        
        let audioManager = VIAudioManager.shared()
        audioManager.delegate = self
        audioDeviceChanged(audioManager.currentAudioDevice())
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }
    
    private func updateContent() {
        if let call = call, let callinfo = call.info {
            let endpoint = callinfo.endpoints.first
            if let userName = endpoint?.user {
                self.userName = userName
            }
            if let userDisplayName = endpoint?.userDisplayName {
                self.userDisplayName = userDisplayName
            }
            endpointDisplayNameLabel.setUser(userDisplayName, userName)
            
            if call.hasConnected && !reconnecting {
                dtmfButton.isEnabled = true // show call duration and unblock buttons
                holdButton.isEnabled = true
                call.isOnHold ? callStateLabel.stopTimer() : callStateLabel.runTimer(with: callinfo.duration())
            } else {
                dtmfButton.isEnabled = false
                holdButton.isEnabled = false
                callStateLabel.text = reconnecting ? "Reconnecting..." : "Connecting..."
                keyPadView.hideHandler?()
            }
            
            if !call.isOnHold {
                holdButton.isSelected = false
                holdButton.label.text = "hold"
                holdButton.setImage(#imageLiteral(resourceName: "hold"), for: .normal)
            } else {
                holdButton.isSelected = true
                holdButton.label.text = "resume"
                holdButton.setImage(#imageLiteral(resourceName: "resumeP"), for: .normal)
                dtmfButton.isEnabled = false
                if !reconnecting {
                    callStateLabel.text = "Call on hold"
                }
            }
            
            self.isMuted = !callinfo.sendAudio
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
    }
    
    @IBAction func muteTouch(_ sender: UIButton) {
        Log.d("Changing mute state")
        if let call = self.call {
            isMuted.toggle()
            let setMute = CXSetMutedCallAction(call: call.uuid, muted: isMuted)
            callController.requestTransaction(with: setMute)
            { (error: Error?) in
                if let error = error {
                    Log.e(error.localizedDescription)
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                }
            }
        }
    }
    
    @IBAction func dtmfTouch(_ sender: UIButton) {
        endpointDisplayNameLabel.text = " " //clear label to show DTMFs
        keyPadView.isHidden = false //show keypad
    }
    
    @IBAction func audioDeviceTouch(_ sender: UIButton) {
        Log.d("Showing audio devices actionSheet")
        showAudioDevicesActionSheet(sourceView: sender)
    }
    
    @IBAction func holdTouch(_ sender: UIButton) {
        sender.isEnabled = false
        if let call = self.call {
            let setHeld = CXSetHeldCallAction(call: call.uuid, onHold: !sender.isSelected)
            callController.requestTransaction(with: setHeld)
            { [weak self] (error: Error?) in
                if let error = error {
                    Log.e("setHold error: \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
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
                    AlertHelper.showError(message: error.localizedDescription, on: self)
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

// MARK: - VIAudioManagerDelegate -
extension CallViewController {
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
}

// MARK: AppLifeCycleDelegate
extension CallViewController {
    func applicationDidBecomeActive(_ application: UIApplication) {
        updateContent()
    }
}

// MARK: CallReconnectDelegate
extension CallViewController {
    func callDidStartReconnecting(uuid: UUID) {
        if self.call?.uuid == uuid {
            self.reconnecting = true
            self.callStateLabel.stopTimer()
            updateContent()
        }
    }
    
    func callDidReconnect(uuid: UUID) {
        if self.call?.uuid == uuid, let call = call, let callinfo = call.info {
            if call.hasConnected {
                self.callStateLabel.runTimer(with: callinfo.duration())
            } else {
                self.callStateLabel.text = "Connecting"
            }
            self.reconnecting = false
            updateContent()
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
