/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK

final class CallViewController:
    UIViewController
{
    @IBOutlet private weak var videoButton: CallOptionButton!
    @IBOutlet private weak var sharingButton: CallOptionButton!
    @IBOutlet private weak var hangupButton: CallOptionButton!
    @IBOutlet private weak var localVideoStreamView: CallVideoView!
    @IBOutlet private weak var magneticView: EdgeMagneticView!
    @IBOutlet private weak var remoteVideoStreamView: CallVideoView!
    @IBOutlet private weak var callStateLabel: UILabel!
    
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callManager.callObserver = updateContent(with:)
        
        videoButton.state = .initial(model: CallOptionButtonModels.camera)
        videoButton.touchUpHandler = videoHandler(_:)
        
        sharingButton.state = .initial(model: CallOptionButtonModels.screen)
        sharingButton.touchUpHandler = sharingHandler(_:)
        
        hangupButton.state = .initial(model: CallOptionButtonModels.hangup)
        hangupButton.touchUpHandler = hangupHandler(_:)
        
        localVideoStreamView.showImage = false
        
        callManager.videoStreamAddedHandler = videoStreamAdded(_:_:)
        callManager.videoStreamRemovedHandler = videoStreamRemoved(_:)
        
        guard let callDirection = callManager.managedCallWrapper?.direction else {
            dismiss(animated: true)
            return
        }
        
        do {
            try callDirection == .outgoing
                ? callManager.startOutgoingCall()
                : callManager.makeIncomingCallActive()
        } catch (let error) {
            Log.e(" \(callDirection) call start failed with error \(error.localizedDescription)")
            dismiss(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let call = callManager.managedCallWrapper {
            updateContent(with: call)
        }
    }
    
    @IBAction private func localVideoStreamTapped(_ sender: UITapGestureRecognizer) {
        VICameraManager.shared().useBackCamera.toggle()
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
    
    func videoStreamAdded(_ local: Bool, _ completion: (VIVideoRendererView) -> Void) {
        if local {
            localVideoStreamView.streamEnabled = true
            completion(VIVideoRendererView(containerView: localVideoStreamView.streamView))
        } else {
            remoteVideoStreamView.streamEnabled = true
            completion(VIVideoRendererView(containerView: remoteVideoStreamView.streamView))
        }
    }
    
    func videoStreamRemoved(_ local: Bool) {
        (local ? localVideoStreamView : remoteVideoStreamView).streamEnabled = false
    }
    
    private func updateContent(with call: CallManager.CallWrapper) {
        if case .ended (let reason) = call.state {
            if case .disconnected = reason {
                self.dismiss(animated: true)
            }
            if case .failed (let message) = reason {
                weak var presentingViewController = self.presentingViewController
                self.dismiss(animated: true) {
                    presentingViewController?.present(
                        self.storyAssembler.callFailed(
                            callee: call.callee,
                            displayName: call.displayName ?? call.callee,
                            reason: message
                        ),
                        animated: true)
                }
                return
            }
        }
            
        sharingButton.state = call.state == .connected
            ? call.sharingScreen ? .selected : .normal
            : .unavailable
        videoButton.state = call.state == .connected
            ? call.sendingVideo ? .normal : .selected
            : .unavailable
        
        localVideoStreamView.streamEnabled = call.sendingVideo && !call.sharingScreen
        
        callStateLabel.text = call.state == .connected ? "Call in progress" : "Connecting..."
    }
    
    private func videoHandler(_ button: CallOptionButton) {
        Log.d("Changing sendVideo")
        button.state = .unavailable
        sharingButton.state = .unavailable
        
        callManager.changeSendVideo { [weak self] error in
            if let error = error {
                Log.e("setSendVideo error \(error.localizedDescription)")
                AlertHelper.showError(message: error.localizedDescription, on: self)
            }
        }
    }
    
    private func sharingHandler(_ button: CallOptionButton) {
        Log.d("Changing sharing")
        button.state = .unavailable
        videoButton.state = .unavailable
        
        callManager.changeShareScreen { [weak self] error in
            if let error = error {
                Log.e("setSharing error \(error.localizedDescription)")
                AlertHelper.showError(message: error.localizedDescription, on: self)
            }
        }
    }
    
    private func hangupHandler(_ button: CallOptionButton) {
        Log.d("Call hangup called")
        button.state = .unavailable
        do {
            try callManager.endCall()
        } catch (let error) {
            Log.e(error.localizedDescription)
        }
        dismiss(animated: true)
    }
    
    private enum CallOptionButtonModels {
        static let screen = CallOptionButtonModel(image: UIImage(named: "screenSharing"), text: "Screen")
        static let camera = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Camera")
        static let hangup = CallOptionButtonModel(image: UIImage(named: "hangup"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Hangup")
    }
}
