/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant
import CocoaLumberjack

class CallViewController: BaseViewController, VICallDelegate, VIEndpointDelegate {
    var call: CallDescriptor?

    @IBOutlet var remoteContainer: UIView?
    @IBOutlet var localContainer: UIView?
    @IBOutlet var dtfmButton: UIButton?
    @IBOutlet var holdButton: UIButton?
    @IBOutlet var loudspeakerButton: UIButton?
    @IBOutlet var muteVideoButton: UIButton?
    @IBOutlet var muteAudioButton: UIButton?
    @IBOutlet var hangButton: UIButton?

    var voximplant: VoxController!

    override func viewDidLoad() {
        self.localContainer?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchCamera)))
        self.remoteContainer?.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(switchVideoResizeMode)))
    }

    @objc func switchVideoResizeMode() {

        let switchVideoResizeModeInStreams: ([VIVideoStream]!) -> () = { streams in

            for stream in streams {
                for renderer in stream.renderers {
                    if renderer is VIVideoRendererView {
                        let videoRendererView = renderer as! VIVideoRendererView
                        videoRendererView.resizeMode = videoRendererView.resizeMode == .fill ? .fit : .fill;
                    }
                }
            }
        }

        switchVideoResizeModeInStreams(self.call?.call.localVideoStreams)
        switchVideoResizeModeInStreams(self.call?.call.endpoints.first!.remoteVideoStreams)
    }

    @objc func switchCamera() {
        VICameraManager.shared().useBackCamera = !VICameraManager.shared().useBackCamera
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        VIAudioManager.shared().delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        VIAudioManager.shared().delegate = nil
    }

    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask     {
        return .all
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.voximplant = AppDelegate.instance().voxImplant!;

        self.call = self.voximplant.callManager!.activeCall
        self.call!.call.add(self)
        self.call!.call.endpoints.first!.delegate = self;

        if let local = self.voximplant.localStream {
            let viewRenderer = VIVideoRendererView(containerView: self.localContainer)
            local.addRenderer(viewRenderer)
        }

        if let remote = self.voximplant.remoteStream {
            let viewRenderer = VIVideoRendererView(containerView: self.remoteContainer)
            remote.addRenderer(viewRenderer)
        }
    }

    @IBAction func dtfmButtonTouched(_ sender: AnyObject?) {
        let alertController = UIAlertController(title: "Send DTFM code", message: "Code to send:", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            let textField = alertController.textFields![0]

            let dtfm : String! = textField.text

            Log.d("DTFM code: \(dtfm)")

            self.call!.call.sendDTMF(dtfm)
         })
        alertController.addTextField { textField in
            textField.placeholder = "*123#"
            textField.keyboardType = .phonePad
         }

        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func holdButtonTouched(_ sender: AnyObject?) {
        let current : Bool! = self.holdButton?.isSelected
        self.call!.call.setHold(!current) { error in
            Log.d("setHold: \(String(describing: error))")
         }
        self.holdButton?.isSelected = !current
    }

    @IBAction func loudspeakerButtonTouched(_ sender: AnyObject?) {
        let devices = VIAudioManager.shared().availableAudioDevices();

        let alertSheet = UIAlertController(title: "Device", message: nil, preferredStyle: .actionSheet);
        for device in devices! {
            alertSheet.addAction(UIAlertAction(title: String(describing: device), style: device.type == VIAudioManager.shared().currentAudioDevice().type ? .destructive : .default) { action in
                VIAudioManager.shared().select(device);
             })
        }
        alertSheet.popoverPresentationController?.sourceView = self.view;
        alertSheet.popoverPresentationController?.sourceRect = self.view.bounds;
        self.present(alertSheet, animated: true, completion: nil)
    }

    @IBAction func muteVideoButtonTouched(_ sender: AnyObject?) {
        let current : Bool! = self.muteVideoButton?.isSelected
        self.call!.call.setSendVideo(current) { error in
            guard error == nil else {
                Log.e("muteVideo: \(String(describing: error))")
                return
            }
            self.muteVideoButton?.isSelected = !current
        }
    }

    @IBAction func muteAudioButtonTouched(_ sender: AnyObject?) {
        let current : Bool! = self.muteAudioButton?.isSelected
        self.call!.call.sendAudio = current
        self.muteAudioButton?.isSelected = !current
    }

    @IBAction func hangupButtonTouched(_ sender: AnyObject?) {
        if let callManager = self.voximplant.callManager, let call = callManager.activeCall {
            callManager.endCall(call)
            call.call.hangup(withHeaders: nil)
        }
    }

    override func vox(_ voximplant: VoxController!, ended call: CallDescriptor!, error: Error?) {
        super.vox(voximplant, ended: call, error: error)

        self.dismiss(animated: true)
    }

    func call(_ call: VICall!, didAddLocalVideoStream videoStream: VIVideoStream!) {
        let viewRenderer = VIVideoRendererView(containerView: self.localContainer)
        videoStream.addRenderer(viewRenderer)
    }

    func endpoint(_ endpoint: VIEndpoint!, didAddRemoteVideoStream videoStream: VIVideoStream!) {
        let viewRenderer = VIVideoRendererView(containerView: self.remoteContainer)
        videoStream.addRenderer(viewRenderer)
    }
}

extension CallViewController: VIAudioManagerDelegate {
    func audioDeviceChanged(_ audioDevice: VIAudioDevice!) {
        Log.v("audioDeviceBecomeDefault: \(String(describing: audioDevice))")
    }

    func audioDevicesListChanged(_ availableAudioDevices: Set<VIAudioDevice>!) {
        Log.v("audioDevicesListChanged: \(availableAudioDevices)")
    }

    func audioDeviceUnavailable(_ audioDevice: VIAudioDevice!) {
        Log.v("audioDeviceUnavailable: \(String(describing: audioDevice))")
    }
}
