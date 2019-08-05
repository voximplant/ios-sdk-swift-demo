/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplant

enum CallNotificationCategory: String {
    case audio = "kAudioCallNotificationCategory"
}

enum CallNotificationAction: String {
    case reject = "kRejectCallNotificationAction"
    case answerAudio = "kAnswerAudioCallNotificationAction"
}

protocol CallManagerDelegate: AnyObject {
    func notifyIncomingCall(_ call: VICall)
}

class CallManager: NSObject, VIClientCallManagerDelegate, VICallDelegate {
    
    var delegate: CallManagerDelegate?
    
    let kCallNotificationIdentifier = "kCallNotificationIdentifier"

    fileprivate var client: VIClient
    fileprivate var authService: AuthService
    
    // Voximplant SDK supports multiple calls at the same time, however
    // this demo app demonstrates only one managed call at the moment,
    // so it rejects new incoming call if there is already a call.
    fileprivate(set) var managedCall: VICall?
    
    func hasManagedCall() -> Bool {
        return managedCall != nil
    }
    
    init(_ client: VIClient, _ authService: AuthService) {
        self.client = client
        self.authService = authService
        super.init()
        self.client.callManagerDelegate = self
    }
    
    func startOutgoingCall(_ contact: String, _ completion: @escaping (Result<(), Error>) -> Void) {
        if let lastLoggedInUser = authService.lastLoggedInUser {
            authService.loginWithAccessToken(user: lastLoggedInUser.fullUsername)
            { [weak self] (result: Result<String, Error>) in
                switch result {
                case let .failure(error):
                    Log.e("Can't start outgoing call: \(error.localizedDescription)")
                    completion(.failure(error))
                case .success(_):
                    if let sself = self,
                       let client = self?.client,
                       !sself.hasManagedCall()
                    {
                        let settings = VICallSettings()
                        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
                        
                        // could be nil only if client is not logged in:
                        if let call: VICall = client.call(contact, settings: settings) {
                            call.add(sself)
                            sself.managedCall = call
                            call.start()
                            completion(.success(()))
                        } else {
                            completion(.failure(VoxDemoError.errorCouldntCreateCall()))
                        }
                    } else {
                        completion(.failure(VoxDemoError.errorAlreadyHasCall()))
                    }
                }
            }
        }
    }

    func makeIncomingCallActive() {
        // assert(self.hasManagedCall())
        // assert(client.clientState == .loggedIn)

        // In this sample we don't need to check the client state in this method - here we are sure we are already logged in to the Voximplant Cloud.
        let settings = VICallSettings()
        settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: false)
        managedCall?.answer(with: settings)
    }

    // MARK: VIClientCallManagerDelegate
    func client(_ client: VIClient, didReceiveIncomingCall call: VICall, withIncomingVideo video: Bool, headers: [AnyHashable: Any]?) {
        if self.hasManagedCall() {
            call.reject(with: .busy, headers: nil)
        } else {
            managedCall = call
            call.add(self)
            delegate?.notifyIncomingCall(call)
        }
    }
    
    // MARK: VICallDelegate
    func call(_ call: VICall, didDisconnectWithHeaders headers: [AnyHashable: Any]?, answeredElsewhere: NSNumber) {
        if case call.callId? = managedCall?.callId {
            call.remove(self)
            managedCall = nil
        }
    }
    
    func call(_ call: VICall, didFailWithError error: Error, headers: [AnyHashable : Any]?) {
        if case call.callId? = managedCall?.callId {
            call.remove(self)
            managedCall = nil
        }
    }
}