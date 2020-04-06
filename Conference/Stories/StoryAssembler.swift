/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplant

fileprivate let client = VIClient(delegateQueue: DispatchQueue.main)
fileprivate let authService: AuthService = VoximplantAuthService(client: client)
fileprivate let conferenceService: ConferenceService = VoximplantConferenceService(client: client)
fileprivate let apiService: VoximplantAPIService = VoximplantAPIService()
fileprivate let permissionsService: PermissionsService = PermissionsService()

final class StoryAssembler {
    static func assembleLogin() -> LoginViewController {
        let controller = Storyboard.main.instantiateViewController(of: LoginViewController.self)
        controller.joinConference = JoinConferenceUseCase(authService: authService, conferenceService: conferenceService,
                                                          apiService: apiService, permissionsService: permissionsService)
        return controller
    }
    
    static func assembleConferenceCall(name: String, video: Bool) -> ConferenceCallViewController {
        let controller = Storyboard.main.instantiateViewController(of: ConferenceCallViewController.self)
        controller.leaveConference = LeaveConferenceUseCase(conferenceService: conferenceService, authService: authService)
        controller.manageConference = ManageConferenceUseCase(conferenceService: conferenceService)
        controller.name = name
        controller.video = video
        return controller
    }
}
