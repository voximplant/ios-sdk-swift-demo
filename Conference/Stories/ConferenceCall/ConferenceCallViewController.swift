/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK

final class ConferenceCallViewController: UIViewController {
    @IBOutlet private weak var conferenceView: ConferenceView!
    @IBOutlet private weak var muteButton: ConferenceCallButton!
    @IBOutlet private weak var chooseAudioButton: ConferenceCallButton!
    @IBOutlet private weak var switchCameraButton: ConferenceCallButton!
    @IBOutlet private weak var videoButton: ConferenceCallButton!
    @IBOutlet private weak var exitButton: ConferenceCallButton!
    
    var manageConference: ManageConference! // DI
    var leaveConference: LeaveConference! // DI
    var name: String! // DI
    var video: Bool! // DI
    private var leftConference = false
    private var muted = false
    private var audioDevices: Set<VIAudioDevice>? {
        VIAudioManager.shared().availableAudioDevices()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        muteButton.state = .initial(model: ConferenceCallButtonModels.mute)
        muteButton.touchUpHandler = muteHandler(_:)
        
        chooseAudioButton.state = .initial(model: ConferenceCallButtonModels.chooseAudio)
        chooseAudioButton.touchUpHandler = chooseAudioHandler(_:)
        
        switchCameraButton.state = .initial(model: ConferenceCallButtonModels.switchCamera)
        switchCameraButton.touchUpHandler = switchCameraHandler(_:)
        
        videoButton.state = .initial(model: ConferenceCallButtonModels.video)
        videoButton.touchUpHandler = videoHandler(_:)
        
        exitButton.state = .initial(model: ConferenceCallButtonModels.exit)
        exitButton.touchUpHandler = exitHandler(_:)
        
        manageConference.conferenceDisconnectedHandler = disconnectedHandler(error:)
        
        manageConference.userAddedHandler = conferenceView.addParticipant(withID:displayName:)
        manageConference.userUpdatedHandler = conferenceView.updateParticipant(withID:displayName:)
        manageConference.userRemovedHandler = conferenceView.removeParticipant(withId:)
        
        manageConference.videoStreamAddedHandler = conferenceView.prepareVideoRendererForStream(participantID:completion:)
        manageConference.videoStreamRemovedHandler = conferenceView.removeVideoStream(participantID:)
        
        conferenceView.addParticipant(withID: myId, displayName: "\(name ?? "") (you)")
        conferenceView.updateParticipant(withID: myId, displayName: "\(name ?? "") (you)")
    }
    
    private func disconnectedHandler(error: Error?) {
        if (self.leftConference) { return }
        AlertHelper.showAlert(
            title: "Disconnected",
            message: "You've been disconnected \(error != nil ? error!.localizedDescription : "")",
            actions: [UIAlertAction(title: "Close", style: .default) { _ in self.dismiss(animated: true) }],
            on: self
        )
    }
    
    private func muteHandler(_ button: ConferenceCallButton) {
        do {
            try manageConference.mute(!muted)
            muted.toggle()
            button.state = muted ? .selected : .normal
        } catch (let error) {
            AlertHelper.showError(message: error.localizedDescription, on: self)
        }
    }
    
    private func chooseAudioHandler(_ button: ConferenceCallButton) {
        showAudioDevices()
    }
    
    private func switchCameraHandler(_ button: ConferenceCallButton) {
        manageConference.switchCamera()
    }
    
    private func videoHandler(_ button: ConferenceCallButton) {
        let previousState = button.state
        button.state = .unavailable
        manageConference.sendVideo(!video) { [weak self] error in
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
    
    private func exitHandler(_ button: ConferenceCallButton) {
        button.state = .unavailable
        leftConference = true
        leaveConference.execute { error in
            if let error = error {
                AlertHelper.showError(message: error.localizedDescription, on: self)
                self.leftConference = false
                button.state = .normal
            } else {
                self.dismiss(animated: true)
            }
        }
    }
    
    private func showAudioDevices() {
        guard let audioDevices = audioDevices else { return }
        let currentDevice = VIAudioManager.shared()?.currentAudioDevice()
        AlertHelper.showActionSheet(
            actions: audioDevices.map { device in
                UIAlertAction(title: makeFormattedString(from: device, isCurrent: currentDevice == device), style: .default) { _ in
                    VIAudioManager.shared().select(device)
                }
            },
            sourceView: chooseAudioButton,
            on: self
        )
    }
    
    private func makeFormattedString(from device: VIAudioDevice, isCurrent: Bool) -> String {
        let formattedString = String(describing: device).replacingOccurrences(of: "VIAudioDevice", with: "")
        return isCurrent ? "\(formattedString) (Current)" : formattedString
    }
}
