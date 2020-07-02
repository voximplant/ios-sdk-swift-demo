/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK
import ReplayKit

final class CallViewController: UIViewController {
    @IBOutlet private weak var conferenceView: ConferenceView!
    @IBOutlet private weak var videoButton: CallOptionButton!
    @IBOutlet private weak var sharingButton: CallOptionButton!
    @IBOutlet private weak var hangupButton: CallOptionButton!
    
    var myDisplayName: String! // DI
    var callManager: CallManager! // DI
    var storyAssembler: StoryAssembler! // DI
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    private var screenSharingButtonSubview: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callManager.callObserver = { [weak self] call in
            guard let self = self else { return }
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
            
            if #available(iOS 12.0, *) {
                self.screenSharingButtonSubview?.tintColor = call.sharingScreen ? #colorLiteral(red: 0.9607843137, green: 0.2941176471, blue: 0.368627451, alpha: 1) : .white
            } else {
                self.sharingButton.state = call.state == .connected
                    ? call.sharingScreen ? .selected : .normal
                    : .unavailable
            }
            self.videoButton.state = call.state == .connected
                ? call.sendingVideo ? .normal : .selected
                : .unavailable
        }
        
        videoButton.state = .initial(model: CallOptionButtonModels.camera)
        videoButton.touchUpHandler = { [weak self] button in
            Log.d("Changing sendVideo")
            let previousState = button.state
            button.state = .unavailable
            
            self?.callManager.changeSendVideo { [weak self] error in
                if let error = error {
                    Log.e("setSendVideo error \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                }
                button.state = previousState
            }
        }
        
        if #available(iOS 12.0, *) {
            sharingButton.state = .initial(model: CallOptionButtonModels.screen)
        } else {
            sharingButton.state = .initial(model: CallOptionButtonModels.screenOld)
        }
        
        sharingButton.touchUpHandler = { _ in
            if #available(iOS 12.0, *) {
                // nothing, besause used handler of RPSystemBroadcastPickerView, which created in self.init() method
            } else if #available(iOS 11.0, *) {
                AlertHelper.showAlert(title: "On iOS 11 enabling screensharing", message: "Open the Control Panel (swipe up from bottom) -> hold down on the Record Button until options appeared -> select ScreenSharingUploadAppex -> start broadcast. If can't find Record Button in Control Panel go to the Settings -> Control Center -> Customize Controls and add Screen Recording to the Control Panel.", defaultAction: true)
            }
        }
        
        if #available(iOS 12.0, *) {
            let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 46, height: 46))
            broadcastPicker.preferredExtension = "com.voximplant.demos.ScreenSharing.ScreenSharingUploadAppex"
            if let button = broadcastPicker.subviews.first as? UIButton {
                button.imageView?.tintColor = UIColor.white
                screenSharingButtonSubview = button.imageView
            }
            sharingButton.addSubview(broadcastPicker)
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
        
        callManager.endpointAddedHandler = conferenceView.addParticipant(withID:displayName:)
        callManager.endpointUpdatedHandler = conferenceView.updateParticipant(withID:displayName:)
        callManager.endpointRemovedHandler = conferenceView.removeParticipant(withId:)
        
        callManager.localVideoStreamAddedHandler = conferenceView.prepareVideoRendererForStream(participantID:completion:)
        callManager.remoteVideoStreamAddedHandler = conferenceView.prepareVideoRendererForStream(participantID:completion:)
        callManager.remoteVideoStreamAddedHandler = conferenceView.prepareVideoRendererForStream(participantID:completion:)
        callManager.remoteVideoStreamRemovedHandler = conferenceView.removeVideoStream(participantID:)
        
        do {
            try callManager.startOutgoingCall()
            conferenceView.addParticipant(withID: myId, displayName: "\(myDisplayName ?? "") (you)")
        } catch (let error) {
            Log.e("Call start failed with error \(error.localizedDescription)")
            dismiss(animated: true)
        }
    }

    deinit {
        callManager.endpointAddedHandler = nil
        callManager.endpointUpdatedHandler = nil
        callManager.endpointRemovedHandler = nil
        callManager.localVideoStreamAddedHandler = nil
        callManager.remoteVideoStreamAddedHandler = nil
        callManager.remoteVideoStreamAddedHandler = nil
        callManager.remoteVideoStreamRemovedHandler = nil
    }   
    
    private enum CallOptionButtonModels {
        static let screenOld = CallOptionButtonModel(image: UIImage(named: "screenSharing"), text: "Screen")
        static let screen = CallOptionButtonModel(image: nil, text: "Screen")
        static let camera = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Camera")
        static let hangup = CallOptionButtonModel(image: UIImage(named: "hangup"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Hangup")
    }
}
