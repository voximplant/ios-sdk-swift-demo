/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

final class StoryAssembler {
    private let authService: AuthService
    private let conferenceService: ConferenceService
    private let apiService: VoximplantAPIService
    
    init(_ authService: AuthService,
         _ conferenceService: ConferenceService,
         _ apiService: VoximplantAPIService
    ) {
        self.authService = authService
        self.conferenceService = conferenceService
        self.apiService = apiService
    }
    
    var login: LoginViewController {
        let controller = Storyboard.main.instantiateViewController(of: LoginViewController.self)
        controller.joinConference = JoinConferenceUseCase(
            authService: authService,
            conferenceService: conferenceService,
            apiService: apiService
        )
        controller.storyAssembler = self
        return controller
    }
    
    func assembleConferenceCall(name: String, video: Bool) -> ConferenceCallViewController {
        let controller = Storyboard.main.instantiateViewController(of: ConferenceCallViewController.self)
        controller.leaveConference = LeaveConferenceUseCase(conferenceService: conferenceService, authService: authService)
        controller.manageConference = ManageConferenceUseCase(conferenceService: conferenceService)
        controller.name = name
        controller.video = video
        return controller
    }
}
