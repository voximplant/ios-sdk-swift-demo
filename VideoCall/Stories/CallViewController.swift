/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK

final class CallViewController:
    UIViewController,
    AudioDeviceAlertSelecting
{
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    @IBOutlet private weak var muteButton: CallOptionButton!
    @IBOutlet private weak var chooseAudioButton: CallOptionButton!
    @IBOutlet private weak var holdButton: CallOptionButton!
    @IBOutlet private weak var videoButton: CallOptionButton!
    @IBOutlet private weak var hangupButton: CallOptionButton!
    @IBOutlet private weak var localVideoStreamView: CallVideoView!
    @IBOutlet private weak var magneticView: EdgeMagneticView!
    @IBOutlet private weak var remoteVideoStreamView: CallVideoView!
    @IBOutlet private weak var callStateLabel: UILabel!
    
    private var shouldDismissAfterAppearing = false
    
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        muteButton.state = .initial(model: CallOptionButtonModels.mute)
        muteButton.touchUpHandler = { [weak self] button in
            Log.d("Changing mute state")
            let previousState = button.state
            button.state = .unavailable
            do {
                try self?.callManager.toggleMute()
                // if success - UI will be updated from callObserver
            } catch CallError.hasNoActiveCall {
                button.state = previousState
                Log.d("Tried to toggle mute state while active call is nil")
                AlertHelper.showError(message: "Could'nt change mute state, active call not found", on: self)
            } catch {
                button.state = previousState
                Log.d("An error during toggle mute state \(error.localizedDescription)")
                AlertHelper.showError(message: "Could'nt change mute state: \(error.localizedDescription)", on: self)
            }
        }
        
        chooseAudioButton.state = .initial(model: CallOptionButtonModels.chooseAudio)
        chooseAudioButton.touchUpHandler = { [weak self] button in
            Log.d("Showing audio devices actionSheet")
            self?.showAudioDevicesActionSheet(sourceView: button)
        }
        
        holdButton.state = .initial(model: CallOptionButtonModels.hold)
        holdButton.touchUpHandler = { [weak self] button in
            Log.d("Changing hold state")
            let previousState = button.state
            button.state = .unavailable
            self?.callManager.toggleHold { [weak self] error in
                if let _ = error as? CallError {
                    button.state = previousState
                    Log.d("Tried to toggle hold state while active call is nil")
                    AlertHelper.showError(message: "Could'nt change hold state, active call not found", on: self)
                } else if let error = error {
                    button.state = previousState
                    Log.d("An error during toggle hold state \(error.localizedDescription)")
                    AlertHelper.showError(message: "Could'nt change hold state: \(error.localizedDescription)", on: self)
                }
                // if success - UI will be updated from callObserver
            }
        }
        
        videoButton.state = .initial(model: CallOptionButtonModels.video)
        videoButton.touchUpHandler = { [weak self] button in
            Log.d("Changing sendVideo state")
            let previousState = button.state
            button.state = .unavailable
            self?.callManager.toggleSendVideo { [weak self] error in
                if let _ = error as? CallError {
                    button.state = previousState
                    Log.d("Tried to toggle sendVideo state while active call is nil")
                    AlertHelper.showError(message: "Could'nt change sendVideo state, active call not found", on: self)
                } else if let error = error {
                    button.state = previousState
                    Log.d("An error during toggle sendVideo state \(error.localizedDescription)")
                    AlertHelper.showError(message: "Could'nt change sendVideo state: \(error.localizedDescription)", on: self)
                }
            }
            // if success - UI will be updated from callObserver
        }
        
        hangupButton.state = .initial(model: CallOptionButtonModels.hangup)
        hangupButton.touchUpHandler = { [weak self] button in
            Log.d("Call hangup called")
            button.state = .unavailable
            do {
                try self?.callManager.endCall()
                // if success - UI will be updated from callObserver
            } catch {
                self?.dismiss(animated: true)
                Log.e(error.localizedDescription)
            }
        }
        
        localVideoStreamView.showImage = false
        
        callManager.callObserver = { [weak self] call in
            self?.updateContent(with: call)
        }
        
        callManager.videoStreamAddedHandler = { [weak self] local, completion in
            guard let self = self else { return }
            if local {
                self.localVideoStreamView.streamEnabled = true
                completion(VIVideoRendererView(containerView: self.localVideoStreamView.streamView))
            } else {
                self.remoteVideoStreamView.streamEnabled = true
                completion(VIVideoRendererView(containerView: self.remoteVideoStreamView.streamView))
            }
        }
        callManager.videoStreamRemovedHandler = { [weak self] local in
            (local ? self?.localVideoStreamView : self?.remoteVideoStreamView)?.streamEnabled = false
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let call = callManager.managedCallWrapper {
            updateContent(with: call)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldDismissAfterAppearing {
            dismiss(animated: true)
        }
    }
    
    @IBAction private func localVideoStreamTapped(_ sender: UITapGestureRecognizer) {
        callManager.switchCamera()
    }
    
    @IBAction private func localVideoStreamDragged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            let translation = sender.translation(in: self.view)
            localVideoStreamView.center = CGPoint(x: localVideoStreamView.center.x + translation.x,
                                                  y: localVideoStreamView.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        case .ended:
            magneticView.rearrangeInnerView()
        default:
            break
        }
    }
    
    // MARK: - Private -
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
        
        muteButton.state = call.isMuted ? .selected : .normal
        videoButton.state = !call.isOnHold && call.state == .connected
            ? call.sendingVideo ? .normal : .selected
            : .unavailable
        holdButton.state = call.state == .connected
            ? call.isOnHold ? .selected : .normal
            : .unavailable
        
        localVideoStreamView.streamEnabled = !call.isOnHold && call.sendingVideo
        callStateLabel.text = call.state == .connected ? "Call in progress" : "Connecting..."
    }
    
    private enum CallOptionButtonModels {
        static let mute = CallOptionButtonModel(image: UIImage(named: "micOn"), imageSelected: UIImage(named: "micOff"), text: "Mic")
        static let chooseAudio = CallOptionButtonModel(image: UIImage(named: "audioDevice"), text: "Audio")
        static let hold = CallOptionButtonModel(image: UIImage(named: "pause"), text: "Hold")
        static let video = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Cam")
        static let hangup = CallOptionButtonModel(image: UIImage(named: "hangup"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Hangup")
    }
}
