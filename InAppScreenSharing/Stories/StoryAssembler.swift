/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import VoxImplantSDK

final class StoryAssembler {
    private let authService: AuthService
    private let callManager: CallManager
    
    init(authService: AuthService, callManager: CallManager) {
        self.authService = authService
        self.callManager = callManager
    }
    
    var login: LoginViewController {
        let controller = Storyboard.main.instantiateViewController(of: LoginViewController.self)
        controller.authService = authService
        controller.storyAssembler = self
        return controller
    }
    
    var main: MainViewController {
        let controller = Storyboard.main.instantiateViewController(of: MainViewController.self)
        controller.authService = authService
        controller.callManager = callManager
        controller.storyAssembler = self
        return controller
    }
    
    var call: CallViewController {
        let controller = Storyboard.call.instantiateViewController(of: CallViewController.self)
        controller.callManager = callManager
        controller.storyAssembler = self
        return controller
    }
    
    var incomingCall: IncomingCallViewController {
        let controller = Storyboard.call.instantiateViewController(of: IncomingCallViewController.self)
        controller.callManager = callManager
        controller.storyAssembler = self
        return controller
    }
    
    func callFailed(callee: String, displayName: String, reason: String) -> CallFailedViewController {
        let controller = Storyboard.call.instantiateViewController(of: CallFailedViewController.self)
        controller.user = callee
        controller.displayName = displayName
        controller.failReason = reason
        controller.authService = authService
        controller.callManager = callManager
        controller.storyAssembler = self
        return controller
    }
}
