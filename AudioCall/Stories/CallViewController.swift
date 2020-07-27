/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

final class CallViewController:
    UIViewController,
    VIAudioManagerDelegate,
    AudioDeviceAlertSelecting
{
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) { return .darkContent }
        else { return .default }
    }
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    @IBOutlet weak var keyPadView: KeyPadView!
    @IBOutlet weak var dtmfButton: ButtonWithLabel!
    @IBOutlet weak var muteButton: ButtonWithLabel!
    @IBOutlet weak var holdButton: ButtonWithLabel!
    @IBOutlet weak var speakerButton: ButtonWithLabel!
    @IBOutlet weak var callStateLabel: LabelWithTimer!
    
    private var shouldDismissAfterAppearing = false
    
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyPadView.DTMFHandler = { [weak self] symbol in
            Log.d("DTMF code: \(symbol)")
            self?.endpointDisplayNameLabel.text? += symbol
            try? self?.callManager.sendDTMF(symbol)
        }
        
        keyPadView.hideHandler = { [weak self] in
            if let self = self, let call = self.callManager.managedCallWrapper {
                self.endpointDisplayNameLabel.text = call.displayName ?? call.callee
            }
            self?.keyPadView.isHidden = true
        }
        
        callStateLabel.additionalText = " - Call in progress"
        
        callManager.callObserver = { [weak self] call in
            self?.updateContent(with: call)
        }
        
        guard let callDirection = callManager.managedCallWrapper?.direction else {
            shouldDismissAfterAppearing = true
            return
        }
        
        do {
            try callDirection == .outgoing
                ? callManager.startOutgoingCall()
                : callManager.makeIncomingCallActive()
        } catch (let error) {
            Log.e(" \(callDirection) call start failed with error \(error.localizedDescription)")
            shouldDismissAfterAppearing = true
        }
        
        VIAudioManager.shared().delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let call = callManager.managedCallWrapper {
            updateContent(with: call)
        }
    }
    
    @IBAction func muteTouch(_ sender: UIButton) {
        Log.d("Changing mute state")
        do {
            try callManager.toggleMute()
            // if success - UI will be updated from callObserver
        } catch CallError.hasNoActiveCall {
            Log.d("Tried to toggle mute state while active call is nil")
            AlertHelper.showError(message: "Could'nt change mute state, active call not found", on: self)
        } catch {
            Log.d("An error during toggle mute state \(error.localizedDescription)")
            AlertHelper.showError(message: "Could'nt change mute state: \(error.localizedDescription)", on: self)
        }
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
        Log.d("Changing hold state")
        sender.isEnabled = false
        
        callManager.toggleHold { [weak self] error in
            if let _ = error as? CallError {
                sender.isEnabled = true
                Log.d("Tried to toggle hold state while active call is nil")
                AlertHelper.showError(message: "Could'nt change hold state, active call not found", on: self)
            } else if let error = error {
                sender.isEnabled = true
                Log.d("An error during toggle hold state \(error.localizedDescription)")
                AlertHelper.showError(message: "Could'nt change hold state: \(error.localizedDescription)", on: self)
            }
            // if success - UI will be updated from callObserver
        }
    }
    
    @IBAction func hangupTouch(_ sender: UIButton) {
        Log.d("Call hangup called")
        sender.isEnabled = false
        do {
            try callManager.endCall()
            // if success - UI will be updated from callObserver
        } catch {
            dismiss(animated: true)
            Log.e(error.localizedDescription)
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
    
    // MARK: - Private -
    private func changeAudioDeviceButtonState(isSelected: Bool, image: UIImage) {
        speakerButton.setImage(image, for: .selected)
        speakerButton.isSelected = isSelected
    }
    
    private func updateContent(with call: CallManager.CallWrapper) {
        if case .ended (let reason) = call.state {
            if case .disconnected = reason {
                dismiss(animated: true)
            }
            if case .failed (let message) = reason {
                navigationController?.setViewControllers(
                    [storyAssembler.callFailed(
                        callee: call.callee,
                        displayName: call.displayName ?? call.callee,
                        reason: message)
                    ],
                    animated: true
                )
            }
            return
        }
        
        endpointDisplayNameLabel.text = call.displayName ?? call.callee
        
        muteButton.isSelected = call.isMuted
        muteButton.label.text = call.isMuted ? "unmute" : "mute"
        
        holdButton.setImage(call.isOnHold ? #imageLiteral(resourceName: "resumeP") : #imageLiteral(resourceName: "hold"), for: .normal)
        holdButton.label.text = call.isOnHold ? "resume" : "hold"
        
        dtmfButton.isEnabled = call.state == .connected
        holdButton.isEnabled = call.state == .connected
        
        switch call.state {
        case .connecting:
            callStateLabel.text = "Connecting..."
        case .ringing:
            callStateLabel.text = "Ringing..."
        case .connected:
            callStateLabel.runTimer(with: call.duration)
        default: break
        }
    }
}
