/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import CallKit

final class StoryAssembler {
    private let authService: AuthService
    private let callManager: CallManager
    private let callController: CXCallController
    
    init(_ authService: AuthService,
         _ callManager: CallManager,
         _ callController: CXCallController
    ) {
        self.authService = authService
        self.callManager = callManager
        self.callController = callController
    }
    
    func assembleLogin() -> LoginViewController {
        let controller = Storyboard.main.instantiateViewController(of: LoginViewController.self)
        controller.authService = authService
        return controller
    }
    
    func assembleMain() -> MainViewController {
        let controller = Storyboard.main.instantiateViewController(of: MainViewController.self)
        controller.modalPresentationStyle = .fullScreen
        controller.authService = authService
        controller.callController = callController
        return controller
    }
    
    func assembleCall() -> CallViewController {
        let controller = Storyboard.main.instantiateViewController(of: CallViewController.self)
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        controller.callController = callController
        controller.getCallInfo = callManager.info(of:)
        callManager.videoStreamAddedHandler = controller.videoStreamAdded(_:_:)
        callManager.videoStreamRemovedHandler = controller.videoStreamRemoved(_:)
        callManager.reconnectDelegate = controller
        return controller
    }
}
