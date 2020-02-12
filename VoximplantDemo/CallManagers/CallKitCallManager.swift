/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import Foundation
import CallKit
import VoxImplantSDK

@available(iOS 10.0, *)
class CallKitCallManager: NSObject, CallManager {
    var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Voximplant")

        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.ringtoneSound = "ringtone.aiff"
        if let logo = UIImage(named: "CallKitLogo") {
            providerConfiguration.iconTemplateImageData = logo.pngData()
        }

        return providerConfiguration
    }
    var provider: CXProvider?
    private let callController = CXCallController()

    private(set) var activeCall: CallDescriptor? = nil
    private(set) var registeredCalls: [UUID: CallDescriptor]! = [:]
    private(set) var pendingCall: CallDescriptor? = nil

    private var startCallAction: CXStartCallAction?

    func call(uuid: UUID!) -> CallDescriptor? {
        return self.registeredCalls[uuid]
    }

    func call(call: VICall!) -> CallDescriptor? {
        for (_, descriptor) in self.registeredCalls {
            if descriptor.call == call {
                return descriptor
            }
        }
        return nil

    }

    func registerCallManager() {
        Log.i("Registering CallKit Call Manager")
        self.provider = CXProvider(configuration: self.providerConfiguration)
        self.provider?.setDelegate(self, queue: nil)
    }

    func registerCall(_ descriptor: CallDescriptor!) {
        self.registeredCalls[descriptor.uuid] = descriptor

        if descriptor.incoming {
            let update = CXCallUpdate()
            var userName = "Unknown caller";
            if let userDisplayName = descriptor.call!.endpoints.first!.userDisplayName {
                userName = userDisplayName
            }
            update.remoteHandle = CXHandle(type: .generic, value: userName)
            update.hasVideo = descriptor.withVideo

            self.provider?.reportNewIncomingCall(with: descriptor.uuid, update: update) { error in
                guard error == nil else {
                    UIHelper.ShowError(error: error?.localizedDescription, action: nil)
                    self.endCall(descriptor)
                    return
                }
            }
        } else {
            let handle = CXHandle(type: .generic, value: "")
            let startAction = CXStartCallAction(call: descriptor.uuid, handle: handle)
            startAction.isVideo = descriptor.withVideo

            let transaction = CXTransaction(action: startAction)
            requestTransaction(transaction)
        }
    }

    func startCall(_ descriptor: CallDescriptor!) {
        descriptor.started = true
        self.activeCall = descriptor
    }

    func endCall(_ descriptor: CallDescriptor!) {
        if self.activeCall?.uuid == descriptor.uuid {
            self.activeCall = nil
        }

        let endTransaction = CXEndCallAction(call: descriptor.uuid)
        let transaction = CXTransaction(action: endTransaction)
        requestTransaction(transaction)
    }

    private func requestTransaction(_ transaction: CXTransaction!) {
        callController.request(transaction) { error in
            if let error = error {
                UIHelper.ShowError(error: error.localizedDescription, action: nil)
            }
        }
    }

    deinit {
        self.provider?.setDelegate(nil, queue: nil)
        self.provider = nil
    }
}

@available(iOS 10.0, *)
extension CallKitCallManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {

    }

    func providerDidBegin(_ provider: CXProvider) {

    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let descriptor = call(uuid: action.callUUID) else {
            action.fail()
            return
        }

        VIAudioManager.shared().callKitConfigureAudioSession(nil)
        AppDelegate.instance().voxImplant!.startCall(call: descriptor)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard let descriptor = call(uuid: action.callUUID) else {
            action.fail()
            return
        }
        descriptor.call.add(self)
        self.provider?.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())

        VIAudioManager.shared().callKitConfigureAudioSession(nil)

        self.startCallAction = action
        AppDelegate.instance().voxImplant!.startCall(call: descriptor)
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let descriptor = call(uuid: action.callUUID) else {
            action.fail()
            return
        }

        VIAudioManager.shared().callKitStopAudio()
        VIAudioManager.shared().callKitReleaseAudioSession()

        descriptor.call.hangup(withHeaders: nil)
        action.fulfill(withDateEnded: Date())

        self.registeredCalls.removeValue(forKey: descriptor.uuid)
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let descriptor = call(uuid: action.callUUID) else {
            action.fail()
            return
        }

        descriptor.call.setHold(!action.isOnHold) { error in
            guard error == nil else {
                UIHelper.ShowError(error: error?.localizedDescription, action: nil)
                action.fail()
                return
            }

            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let descriptor = call(uuid: action.callUUID) else {
            action.fail()
            return
        }

        descriptor.call.sendAudio = !action.isMuted

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard let descriptor = call(uuid: action.callUUID) else {
            action.fail()
            return
        }

        descriptor.call.sendDTMF(action.digits)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStartAudio()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VIAudioManager.shared().callKitStopAudio()
    }
}

@available(iOS 10.0, *)
extension CallKitCallManager: VICallDelegate {
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable: Any]?) {
        if let descriptor = self.call(call: call) {
            self.provider?.reportCall(with: descriptor.uuid, endedAt: Date(), reason: .failed)
        }

        if let action = self.startCallAction {
            action.fail()
            self.startCallAction = nil
        }
    }

    func call(_ call: VICall, didConnectWithHeaders headers: [AnyHashable: Any]?) {
        if let descriptor = self.call(call: call) {
            self.provider?.reportOutgoingCall(with: descriptor.uuid, connectedAt: Date())

            if let userName = call.endpoints.first?.userDisplayName {
                let update = CXCallUpdate()
                let handle = CXHandle(type: .generic, value: userName)
                update.remoteHandle = handle

                self.provider?.reportCall(with: descriptor.uuid, updated: update)
            }
        }

        if let action = self.startCallAction {
            action.fulfill(withDateStarted: Date())
            self.startCallAction = nil
        }
    }

    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable: Any]?, answeredElsewhere: NSNumber) {
        if let descriptor = self.call(call: call) {
            self.endCall(descriptor)
        }
    }
}
