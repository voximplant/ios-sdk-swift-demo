/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK
import CallKit

final class StoryAssembler {
    private let client: VIClient
    private let authService: AuthService
    private let callManager: CallManager
    private let callController: CXCallController
    
    required init(
        _ client: VIClient,
        _ authService: AuthService,
        _ callManager: CallManager,
        _ callController: CXCallController
    ) {
        self.client = client
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
        return controller
    }
}
