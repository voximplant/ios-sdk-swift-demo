/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK
import CallKit

final class CallViewController:
    UIViewController,
    AppLifeCycleDelegate,
    CXCallObserverDelegate,
    AudioDeviceSelecting
{
    @IBOutlet private weak var muteButton: CallOptionButton!
    @IBOutlet private weak var chooseAudioButton: CallOptionButton!
    @IBOutlet private weak var holdButton: CallOptionButton!
    @IBOutlet private weak var videoButton: CallOptionButton!
    @IBOutlet private weak var hangupButton: CallOptionButton!
    @IBOutlet private weak var localVideoStreamView: CallVideoView!
    @IBOutlet private weak var magneticView: EdgeMagneticView!
    @IBOutlet private weak var remoteVideoStreamView: CallVideoView!
    @IBOutlet private weak var callStateLabel: UILabel!
    
    var callController: CXCallController! // DI
    var getCallInfo: ((CXCall) -> VICall?)! // DI
    
    private var call: CXCall? { callController.callObserver.calls.first }
    private var muted = false
    private var onHold = false
    private var sendingVideo = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        muteButton.state = .initial(model: CallOptionButtonModels.mute)
        muteButton.touchUpHandler = muteHandler(_:)
        
        chooseAudioButton.state = .initial(model: CallOptionButtonModels.chooseAudio)
        chooseAudioButton.touchUpHandler = chooseAudioHandler(_:)
        
        holdButton.state = .initial(model: CallOptionButtonModels.hold)
        holdButton.touchUpHandler = holdHandler(_:)
        
        videoButton.state = .initial(model: CallOptionButtonModels.video)
        videoButton.touchUpHandler = videoHandler(_:)
        
        hangupButton.state = .initial(model: CallOptionButtonModels.hangup)
        hangupButton.touchUpHandler = hangupHandler(_:)
        
        localVideoStreamView.showImage = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
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
    
    private func updateContent() {
        if let call = self.call,
           let callinfo = getCallInfo(call)
        {
            muted = !callinfo.sendAudio
            onHold = call.isOnHold
            
            muteButton.state = muted ? .selected : .normal
            
            localVideoStreamView.streamEnabled = !onHold && sendingVideo

            callStateLabel.text = onHold
                ? "Call is on hold"
                : (call.hasConnected ? "Call in progress" : "Connecting...")
            
            videoButton.state = onHold || !call.hasConnected
                ? .unavailable
                : (sendingVideo ? .normal : .selected)
            
            holdButton.state = call.hasConnected
                ? (onHold ? .selected : .normal)
                : .unavailable
        }
    }
    
    private func muteHandler(_ button: CallOptionButton) {
        Log.d("Changing mute state")
        if let call = self.call {
            let setMute = CXSetMutedCallAction(call: call.uuid, muted: !muted)
            callController.requestTransaction(with: setMute)
            { [weak self] (error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    Log.e("setMute error: \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription)
                } else {
                    self.muted.toggle()
                }
                button.state = self.muted ? .selected : .normal
            }
        }
    }
    
    private func chooseAudioHandler(_ button: CallOptionButton) {
        Log.d("Showing audio devices actionSheet")
        showAudioDevicesActionSheet(sourceView: button)
    }
    
    private func holdHandler(_ button: CallOptionButton) {
        Log.d("Changing hold state")
        button.state = .unavailable
         if let call = self.call {
             let setHeld = CXSetHeldCallAction(call: call.uuid, onHold: !onHold)
             callController.requestTransaction(with: setHeld)
             { [weak self] (error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    Log.e("setHold error: \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                 } else {
                    self.onHold.toggle()
                }
                button.state = self.onHold ? .selected : .normal
            }
        }
    }
    
    private func videoHandler(_ button: CallOptionButton) {
        Log.d("Changing sendVideo")
        button.state = .unavailable
        if let call = call,
            let viCall = getCallInfo(call) {
            viCall.setSendVideo(!sendingVideo) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    Log.d("setSendVideo error \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                } else {
                    self.sendingVideo.toggle()
                }
                button.state = self.sendingVideo ? .normal : .selected
            }
        }
    }
    
    private func hangupHandler(_ button: CallOptionButton) {
        Log.d("Call hangup called")
        button.state = .unavailable
        if let call = self.call {
            // stop call if call exists
            let doEndCall = CXEndCallAction(call: call.uuid)
            callController.requestTransaction(with: doEndCall)
            { (error: Error?) in
                if let error = error {
                    Log.d("Call hangup error: \(error.localizedDescription)")
                    AlertHelper.showError(message: error.localizedDescription, on: self)
                }
                button.state = .normal
            }
        }
    }
    
    // MARK: - CXCallObserverDelegate -
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        updateContent()
        if call.hasEnded {
            Log.d("\(#function) called on \(String(describing: self))")
            dismiss(animated: true)
        }
    }
    
    // MARK: - AppLifeCycleDelegate -
    func applicationDidBecomeActive(_ application: UIApplication) {
        updateContent()
    }
    
    // MARK: - Private -
    private enum CallOptionButtonModels {
        static let mute = CallOptionButtonModel(image: UIImage(named: "micOn"), imageSelected: UIImage(named: "micOff"), text: "Mic")
        static let chooseAudio = CallOptionButtonModel(image: UIImage(named: "audioDevice"), text: "Audio")
        static let hold = CallOptionButtonModel(image: UIImage(named: "hold"), text: "Hold")
        static let video = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Cam")
        static let hangup = CallOptionButtonModel(image: UIImage(named: "hangup"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Hangup")
    }
}
