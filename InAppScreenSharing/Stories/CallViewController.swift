/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK
import ReplayKit

final class CallViewController:
    UIViewController,
    RPScreenRecorderDelegate
{
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    @IBOutlet private weak var videoButton: CallOptionButton!
    @IBOutlet private weak var sharingButton: CallOptionButton!
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
        
        RPScreenRecorder.shared().delegate = self
        
        callManager.callObserver = { [weak self] call in
            self?.updateContent(with: call)
        }
        
        videoButton.state = .initial(model: CallOptionButtonModels.camera)
        videoButton.touchUpHandler = { [weak self] button in
            Log.d("Changing sendVideo")
            button.state = .unavailable
            self?.sharingButton.state = .unavailable
            
            self?.callManager.toggleSendVideo { error in
                if let error = error {
                    Log.e("setSendVideo error \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                }
            }
        }
        
        sharingButton.state = .initial(model: CallOptionButtonModels.screen)
        sharingButton.touchUpHandler = { [weak self] button in
            Log.d("Changing sharing")
            button.state = .unavailable
            self?.videoButton.state = .unavailable
            self?.callManager.toggleShareScreen { error in
                if let error = error {
                    Log.e("setSharing error \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                }
            }
        }
        
        hangupButton.state = .initial(model: CallOptionButtonModels.hangup)
        hangupButton.touchUpHandler = { [weak self] button in
            Log.d("Call hangup called")
            button.state = .unavailable
            do {
                try self?.callManager.endCall()
            } catch (let error) {
                Log.e(error.localizedDescription)
            }
            self?.dismiss(animated: true)
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
        
        localVideoStreamView.showImage = false
        
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
    
    // MARK: - RPScreenRecorderDelegate
    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: Error?
    ) {
        AlertHelper.showAlert(title: "Broadcast", message: "Broadcast has been ended \(error.debugDescription)", on: self)
    }
    
    private enum CallOptionButtonModels {
        static let screen = CallOptionButtonModel(image: UIImage(named: "screenSharing"), text: "Screen")
        static let camera = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Camera")
        static let hangup = CallOptionButtonModel(image: UIImage(named: "hangup"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Hangup")
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
        
        sharingButton.state = call.state == .connected
            ? call.sharingScreen ? .selected : .normal
            : .unavailable
        videoButton.state = call.state == .connected
            ? call.sendingVideo ? .normal : .selected
            : .unavailable
        
        localVideoStreamView.streamEnabled = call.sendingVideo && !call.sharingScreen
        
        callStateLabel.text = call.state == .connected
            ? "Call in progress"
            : "Connecting..."
    }
}
