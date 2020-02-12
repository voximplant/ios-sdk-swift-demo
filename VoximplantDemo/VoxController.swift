/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import Foundation
import Dispatch
import VoxImplantSDK
import UserNotifications

class VoxController: NSObject {
    let client: VIClient
    var callManager: CallManager?

    var cameraHelper: AnyObject?

    weak var delegate: VoxControllerDelegate? {
        didSet {
            Log.i("VoxController delegate changed to \(String(describing: self.delegate))")
        }
    }

    var localStream: VIVideoStream?
    var remoteStream: VIVideoStream?

    var otp: Bool! = false

    fileprivate var user: String!
    fileprivate var password: String?
    fileprivate var oneTimeKey: String?
    fileprivate var gateway: String?

    fileprivate var loginSuccess: VILoginSuccess?
    fileprivate var loginFailure: VILoginFailure?

    var voipPushToken: Data?
    var imPushToken: Data?

    var successCompletion: VILoginSuccess?
    var failureCompletion: VILoginFailure?

    var loginCompletion: ((Error?) -> (Void))?
    var completion: ((Error?) -> (Void))?
    var pushNotificationCompletion: (() -> Void)?

    override init() {
        VIClient.setLogLevel(.info)

        self.client = VIClient(delegateQueue: DispatchQueue.main)

        super.init()

        self.user = Settings.shared.userLogin

        self.successCompletion = {
            [unowned self] (displayName, authParams) in
            Settings.shared.userLogin = self.user

            Log.v("authParams: \(String(describing: authParams))")

            Settings.shared.refreshExpire = Date(timeIntervalSinceNow: authParams.refreshExpire)
            Settings.shared.accessExpire = Date(timeIntervalSinceNow: authParams.accessExpire)
            Settings.shared.refreshToken = authParams.refreshToken
            Settings.shared.accessToken = authParams.accessToken

            self.client.registerPushNotificationsToken(self.voipPushToken, imToken: self.imPushToken)

            self.loginSuccess?(displayName, authParams)

            if let completion = self.completion {
                completion(nil)
                self.completion = nil
            }

            if let delegate = self.delegate {
                delegate.voxDidLoggedIn(self)
            }
        }
        self.failureCompletion = {
            [unowned self] (error) in
            self.client.disconnect()

            if let completion = self.completion {
                completion(error)
                self.completion = nil
            }

            self.loginFailure?(error)
        }

        self.changeCallManager()
        self.client.sessionDelegate = self
        self.client.callManagerDelegate = self

        if #available(iOS 10.0, *), self.callManager is CallKitCallManager {
            self.registerForPushNotifications()
        }
    }

    private func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.checkPermissions()
            }
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.checkPermissions()
            }
        }
    }

    func checkPermissions() {

        var needAudio = false, needVideo = false

        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            self.requestRecordPermission()
            return
        case .denied:
            needAudio = true
        default:
            Log.i("Record permission granted")
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            self.requestCameraPermission()
            return
        case .restricted, .denied:
            needVideo = true
        default:
            Log.i("Camera permission granted")
        }

        if needAudio || needVideo {
            let action = UIAlertAction(title: "Settings", style: .default) { action in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            }
            UIHelper.ShowError(error: "Microphone and Camera permissions required!", action: action)
        }
    }

    func changeCallManager() {
        if #available(iOS 10.0, *) {
            let useCallKit = AppDelegate.instance().callKit
            self.callManager = useCallKit! ? CallKitCallManager() : NotificationCallManager()
        } else {
            self.callManager = NotificationCallManager()
        }
        self.callManager!.registerCallManager()
    }

    func setGateway(gateway: String?) {
        if (self.gateway == gateway) {
            return
        }

        if (self.client.clientState != .disconnected) {
            self.client.disconnect()
        }

        self.gateway = gateway
    }

    func login(user: String!, password: String!, success: VILoginSuccess?, failure: VILoginFailure?) {
        self.user = user

        self.loginSuccess = success
        self.loginFailure = failure

        self.loginCompletion = { error in
            if let error = error {
                self.failureCompletion?(error)
            } else {
                Log.i("Logging in with login and password")
                self.client.login(withUser: String(format: "%@.voximplant.com", arguments: [self.user]), password: password, success: self.successCompletion, failure: self.failureCompletion)
            }
        }

        self.reconnect(completion: nil)
    }

    func loginWithOneTimeKey(user: String!, password: String!, success: VILoginSuccess?, failure: VILoginFailure?) {
        self.user = user

        self.loginSuccess = success
        self.loginFailure = failure

        self.loginCompletion = { error in
            if let error = error {
                self.failureCompletion?(error)
            } else {
                Log.i("Logging in with login and one time key")
                self.client.requestOneTimeKey(withUser: String(format: "%@.voximplant.com", arguments: [self.user!])) { otk, error in
                    if let otk = otk {
                        Log.i("One Time Key received: \(otk)")
                        let oneTimeKey = self.MD5(String(format: "%@|%@", arguments: [
                            otk,
                            self.MD5(String(format: "%@:voximplant.com:%@", arguments: [
                                self.user!.split(separator: "@").map(String.init).first!,
                                password
                            ]))
                        ]))
                        self.client.login(withUser: String(format: "%@.voximplant.com", arguments: [self.user!]), oneTimeKey: oneTimeKey, success: self.successCompletion, failure: self.failureCompletion)
                    } else {
                        self.failureCompletion?(error!)
                    }
                }
            }
        }

        self.reconnect(completion: nil)
    }

    func loginWithToken(user: String!, success: VILoginSuccess?, failure: VILoginFailure?) {
        self.user = user

        self.loginSuccess = success
        self.loginFailure = failure

        self.loginCompletion = { error in
            if let error = error {
                self.failureCompletion?(error)
            } else {
                Log.i("Logging in with login and access token")
                if let token = Settings.shared.accessToken, let expire = Settings.shared.accessExpire, !token.isEmpty, Date() < expire {
                    Log.i("Access token is fresh")
                    self.client.login(withUser: String(format: "%@.voximplant.com", arguments: [self.user]), token: token, success: self.successCompletion, failure: self.failureCompletion)
                } else if let token = Settings.shared.refreshToken, let expire = Settings.shared.refreshExpire, !token.isEmpty, Date() < expire {
                    Log.i("Access token is outdated, refreshing")
                    self.client.refreshToken(withUser: String(format: "%@.voximplant.com", arguments: [self.user]), token: token) { authParams, error in
                        Log.v("RefreshToken authParams: \(String(describing: authParams)), error: \(error?.localizedDescription ?? "no error")")
                        if let err = error {
                            self.failureCompletion?(err)
                        } else {
                            Settings.shared.refreshExpire = Date(timeIntervalSinceNow: authParams!.refreshExpire)
                            Settings.shared.accessExpire = Date(timeIntervalSinceNow: authParams!.accessExpire)
                            Settings.shared.refreshToken = authParams!.refreshToken
                            Settings.shared.accessToken = authParams!.accessToken

                            self.loginWithToken(user: self.user, success: self.successCompletion, failure: self.failureCompletion)
                        }
                    }
                } else {
                    let error = "Access and refresh tokens are outdated";
                    Log.e(error)
                    self.failureCompletion?(NSError(domain: "com.voximplant.demo", code: VILoginError.tokenExpired.rawValue, userInfo: [NSLocalizedDescriptionKey: error]))
                }
            }
        }

        self.reconnect(completion: nil)
    }

    func MD5(_ string: String) -> String {
        let messageData = string.data(using: .utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))

        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }

        return digestData.map {
            String(format: "%02hhx", $0)
        }.joined()
    }

    func logout() {
        Log.i("Logging out")
        self.client.unregisterPushNotificationsToken(self.voipPushToken, imToken: self.imPushToken)

        self.client.disconnect()

        Settings.shared.accessExpire = nil
        Settings.shared.refreshExpire = nil
        Settings.shared.accessToken = nil
        Settings.shared.refreshToken = nil

        if let delegate = self.delegate {
            delegate.voxDidLoggedOut(self)
        }
    }

    func startOutgoingCall(_ contact: String!, withVideo: Bool!) {
        self.reconnect { error in
            let settings = VICallSettings()
            settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: withVideo, sendVideo: withVideo)
            settings.customData = "Voximplant swift demo"
            settings.preferredVideoCodec = AppDelegate.instance().preferredCodec
            let call = self.client.call(contact, settings: settings)

            let descriptor = CallDescriptor(call: call, uuid: UUID(), video: withVideo, incoming: false)

            self.callManager!.registerCall(descriptor)

            if let delegate = self.delegate {
                delegate.vox(self, prepared: descriptor)
            }
        }
    }

    private func reconnect(completion: ((Error?) -> (Void))?) {
        self.completion = completion
        if self.client.clientState == .disconnected {
            if let gateway = self.gateway, !gateway.isEmpty {
                self.client.connect(withConnectivityCheck: false, gateways: [gateway])
            } else {
                self.client.connect(withConnectivityCheck: false, gateways: nil)
            }
        } else if self.client.clientState == .connected {
            if let loginCompletion = self.loginCompletion {
                loginCompletion(nil)
                self.loginCompletion = nil
            } else {
                self.loginWithToken(user: self.user, success: nil, failure: nil)
            }
        } else if self.client.clientState == .loggedIn, let completion = self.completion {
            completion(nil)
            self.completion = nil
        }
    }

    func startCall(call: CallDescriptor!) {
        guard self.callManager != nil else {
            Log.e("CallManager not available")
            return
        }

        let callCompletion = { (error: Error?) in
            if let err = error {
                UIHelper.ShowError(error: err.localizedDescription)
                return;
            }
            call.call.add(self)
            call.call.endpoints.first!.delegate = self;

            if let cameraMode = AppDelegate.instance().cameraMode {
                switch cameraMode {
                case .Normal:
                    self.cameraHelper = nil
                    break;
                case .Preprocessing:
                    self.cameraHelper = CameraPreprocessor()
                    break;
                case .Custom:
                    self.cameraHelper = CustomCamera()
                    call.call.videoSource = (self.cameraHelper as! CustomCamera).customVideoSource
                    break;
                }
            }

            self.callManager!.startCall(call)
            VIAudioManager.shared().select(VIAudioDevice(type: call.withVideo ? .speaker : .none))
            if (call.incoming) {
                let settings = VICallSettings()
                settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: call.withVideo, sendVideo: call.withVideo)
                settings.customData = "Voximplant swift demo"
                settings.preferredVideoCodec = AppDelegate.instance().preferredCodec
                call.call.answer(with: settings)
            } else {
                call.call.start()
            }
        }

        self.reconnect(completion: callCompletion)
    }

    func rejectCall(call: CallDescriptor!, mode: VIRejectMode) {
        call.call.reject(with: mode, headers: nil)
        self.callManager!.endCall(call)
    }
}

extension VoxController: VICallDelegate, VIEndpointDelegate, VIClientCallManagerDelegate {
    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable: Any]?) {
        if let compl = self.pushNotificationCompletion {
            compl()
            self.pushNotificationCompletion = nil
        }

        UIHelper.ShowCallScreen()
    }

    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable: Any]?) {
        Log.v("didFailWithError \(error)")
        if let compl = self.pushNotificationCompletion {
            compl()
            self.pushNotificationCompletion = nil
        }

        if let delegate = self.delegate {
            delegate.vox(self, ended: self.callManager!.call(call: call), error: error)
        }
    }

    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable: Any]?, answeredElsewhere: NSNumber) {
        if let compl = self.pushNotificationCompletion {
            compl()
            self.pushNotificationCompletion = nil
        }

        if let delegate = self.delegate {
            delegate.vox(self, ended: self.callManager!.call(call: call), error: nil)
        }
    }

    func call(_ call: VICall, didAddLocalVideoStream videoStream: VIVideoStream) {
        Log.d("didAddLocalVideoStream: \(call.callId) \(String(describing: videoStream.streamId))", context: self)
        self.localStream = videoStream
    }

    func call(_ call: VICall, didRemoveLocalVideoStream videoStream: VIVideoStream) {
        self.localStream = nil
    }

    func call(_ call: VICall, didAdd endpoint: VIEndpoint) {
        if let delegate = self.delegate {
            delegate.vox(self, call: self.callManager!.call(call: call), didAdd: endpoint);
        }
    }

    func call(_ call: VICall, startRingingWithHeaders headers: [AnyHashable: Any]?) {
        if let delegate = self.delegate {
            delegate.vox(self, startRinging: self.callManager!.call(call: call))
        }
    }

    func callDidStartAudio(_ call: VICall) {
        if let delegate = self.delegate {
            delegate.vox(self, stopRinging: self.callManager!.call(call: call))
        }
    }

    func endpoint(_ endpoint: VIEndpoint, didAddRemoteVideoStream videoStream: VIVideoStream) {
        Log.d("didAddRemoteVideoStream: \(endpoint.endpointId) \(endpoint.userDisplayName ?? "") \(String(describing: videoStream.streamId))", context: self)
        self.remoteStream = videoStream
    }

    func client(_ client: VIClient, didReceiveIncomingCall call: VICall, withIncomingVideo video: Bool, headers: [AnyHashable: Any]?) {
        let descriptor = CallDescriptor(call: call, uuid: UUID(), video: video, incoming: true)
        self.callManager!.registerCall(descriptor)
        call.add(self.callManager!)
    }
}

import PushKit

extension VoxController: PKPushRegistryDelegate {
    func registerForPushNotifications() {
        if #available(iOS 13.0, *) { return }
        // VoIP
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.desiredPushTypes = [.voIP]
        voipRegistry.delegate = self

        // IM
        if #available(iOS 10.0, *) {
            self.checkRemoteNotificationSettings()
        } else {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    @available(iOS 10.0, *)
    private func checkRemoteNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings: UNNotificationSettings) in
            guard settings.authorizationStatus == .authorized else {
                Log.e("Remote notifications denied")
                UIHelper.ShowError(error: "Remote notifications denied")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func remoteNotificationsCallback(_ param: Any!) {
        if let error = param as? Error {
            UIHelper.ShowError(error: error.localizedDescription)
        } else if let token = param as? Data {
            let tokenString = token.map {
                String(format: "%02hhx", $0)
            }.joined()
            Log.i("Remote notifications token: \(tokenString)")

            self.imPushToken = token
        }
    }

    func didReceiveRemoteNotification(payload: [AnyHashable: Any]) {
        let messengerEvent = (VIMessengerPushNotificationProcessing.processPushNotification(payload) as! VIMessageEvent)
        Log.i("event = \(messengerEvent.eventType.rawValue), conversation = \(String(describing: messengerEvent.message.conversation))")
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map {
            String(format: "%02hhx", $0)
        }.joined()
        Log.i("New push credentials: \(token) for \(type)")
        self.voipPushToken = pushCredentials.token
    }

    @available(iOS 11.0, *)
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        Log.i("\(type) Push Received: \(payload) [iOS 11 branch]")
        self.pushNotificationCompletion = completion

        self.client.handlePushNotification(payload.dictionaryPayload)

        self.reconnect(completion: nil)
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        Log.i("\(type) Push Received: \(payload) [iOS 10 branch]")
        self.client.handlePushNotification(payload.dictionaryPayload)

        self.reconnect(completion: nil)
    }
}

extension VoxController: VIClientSessionDelegate {
    func clientSessionDidConnect(_ client: VIClient) {
        Log.i("Connected!")
        Settings.shared.serverGateway = self.gateway

        if let completion = self.loginCompletion {
            completion(nil)
            self.loginCompletion = nil
        } else {
            self.loginWithToken(user: self.user, success: nil, failure: nil)
        }
    }

    func clientSessionDidDisconnect(_ client: VIClient) {
        Log.i("Disconnected!")

        if let delegate = self.delegate {
            delegate.voxDidLoggedOut(self)
        }
    }

    func client(_ client: VIClient, sessionDidFailConnectWithError error: Error) {
        Log.e("Failed to connect! \(error.localizedDescription)")

        if let completion = self.loginCompletion {
            completion(error)
            self.loginCompletion = nil
        }

        UIHelper.ShowError(error: error.localizedDescription)
    }
}

protocol VoxControllerDelegate: class {
    func voxDidLoggedIn(_ voximplant: VoxController!)
    func voxDidLoggedOut(_ voximplant: VoxController!)

    func vox(_ voximplant: VoxController!, prepared call: CallDescriptor!)
    func vox(_ voximplant: VoxController!, started call: CallDescriptor!)
    func vox(_ voximplant: VoxController!, ended call: CallDescriptor!, error: Error?)
    func vox(_ voximplant: VoxController!, call: CallDescriptor!, didAdd endpoint: VIEndpoint!)

    func vox(_ voximplant: VoxController!, startRinging call: CallDescriptor!)
    func vox(_ voximplant: VoxController!, stopRinging call: CallDescriptor!)
}
