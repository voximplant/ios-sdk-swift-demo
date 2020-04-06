/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol LeaveConference {
    func execute(_ completion: @escaping (Error?) -> Void)
}

final class LeaveConferenceUseCase: LeaveConference {
    private let conferenceService: ConferenceService
    private let authService: AuthService
    
    required init(conferenceService: ConferenceService, authService: AuthService) {
        self.conferenceService = conferenceService
        self.authService = authService
    }
    
    func execute(_ completion: @escaping (Error?) -> Void) {
        do {
            try conferenceService.leaveConference()
            authService.logout { completion(nil) }
        } catch (let error) {
            completion(error)
        }
    }
}
