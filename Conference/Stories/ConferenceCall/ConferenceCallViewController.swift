/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class ConferenceCallViewController:
    UIViewController,
    AudioDeviceAlertSelecting
{
    @IBOutlet private weak var conferenceView: ConferenceView!
    @IBOutlet private weak var muteButton: CallOptionButton!
    @IBOutlet private weak var chooseAudioButton: CallOptionButton!
    @IBOutlet private weak var switchCameraButton: CallOptionButton!
    @IBOutlet private weak var videoButton: CallOptionButton!
    @IBOutlet private weak var exitButton: CallOptionButton!
    
    var manageConference: ManageConference! // DI
    var leaveConference: LeaveConference! // DI
    var name: String! // DI
    var video: Bool! // DI
    private var leftConference = false
    private var muted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        muteButton.state = .initial(model: CallOptionButtonModels.mute)
        muteButton.touchUpHandler = { [weak self] button in
            guard let self = self else { return }
            do {
                try self.manageConference.mute(!self.muted)
                self.muted.toggle()
                button.state = self.muted ? .selected : .normal
            } catch (let error) {
                AlertHelper.showError(message: error.localizedDescription, on: self)
            }
        }
        
        chooseAudioButton.state = .initial(model: CallOptionButtonModels.chooseAudio)
        chooseAudioButton.touchUpHandler = { [weak self] button in
            self?.showAudioDevicesActionSheet(sourceView: button)
        }
        
        switchCameraButton.state = .initial(model: CallOptionButtonModels.switchCamera)
        switchCameraButton.touchUpHandler = { [weak self] _ in
            self?.manageConference.switchCamera()
        }
        
        videoButton.state = .initial(model: CallOptionButtonModels.video)
        videoButton.touchUpHandler = { [weak self] button in
            guard let self = self else { return }
            let previousState = button.state
            button.state = .unavailable
            self.manageConference.sendVideo(!self.video) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                    button.state = previousState
                } else {
                    self.video.toggle()
                    self.conferenceView.hideVideoRenderer(!self.video, for: myId)
                    button.state = self.video ? .normal : .selected
                }
            }
        }
        
        exitButton.state = .initial(model: CallOptionButtonModels.exit)
        exitButton.touchUpHandler = { [weak self] button in
            guard let self = self else { return }
            button.state = .unavailable
            self.leftConference = true
            self.leaveConference.execute { error in
                if let error = error {
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                    self.leftConference = false
                    button.state = .normal
                } else {
                    self.dismiss(animated: true)
                }
            }
        }
        
        manageConference.conferenceDisconnectedHandler = { [weak self] error in
            guard let self = self, !self.leftConference else { return }
            self.leaveConference.execute { error in
                if let error = error {
                    print("Got an error while leaving conference - \(error.localizedDescription)")
                }
            }
            AlertHelper.showAlert(
                title: "Disconnected",
                message: "You've been disconnected \(error != nil ? error!.localizedDescription : "")",
                actions: [UIAlertAction(title: "Close", style: .default) { _ in self.dismiss(animated: true) }],
                on: self
            )
        }
        
        manageConference.userAddedHandler = conferenceView.addParticipant(withID:displayName:)
        manageConference.userUpdatedHandler = conferenceView.updateParticipant(withID:displayName:)
        manageConference.userRemovedHandler = conferenceView.removeParticipant(withId:)
        
        manageConference.videoStreamAddedHandler = conferenceView.prepareVideoRendererForStream(participantID:completion:)
        manageConference.videoStreamRemovedHandler = conferenceView.removeVideoStream(participantID:)
        
        conferenceView.addParticipant(withID: myId, displayName: "\(name ?? "") (you)")
        conferenceView.updateParticipant(withID: myId, displayName: "\(name ?? "") (you)")
    }
    
    private enum CallOptionButtonModels {
        static let mute = CallOptionButtonModel(image: UIImage(named: "micOn"), imageSelected: UIImage(named: "micOff"), text: "Mic")
        static let chooseAudio = CallOptionButtonModel(image: UIImage(named: "audioDevice"), text: "Audio")
        static let switchCamera = CallOptionButtonModel(image: UIImage(named: "switchCam"), text: "Switch")
        static let video = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Cam")
        static let exit = CallOptionButtonModel(image: UIImage(named: "exit"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Leave")
    }
}
