/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol JoinConference {
    func execute(withId id: String, andName name: String, sendVideo video: Bool, completion: @escaping (Error?) -> Void)
}

final class JoinConferenceUseCase: JoinConference {
    private let authService: AuthService
    private let conferenceService: ConferenceService
    private let apiService: VoximplantAPIService
    
    required init(authService: AuthService, conferenceService: ConferenceService, apiService: VoximplantAPIService) {
        self.authService = authService
        self.conferenceService = conferenceService
        self.apiService = apiService
    }
    
    func execute(withId id: String, andName name: String, sendVideo video: Bool, completion: @escaping (Error?) -> Void) {
        PermissionsHelper.requestRecordPermissions(includingVideo: video) { error in
            if let error = error {
                completion(error)
            } else {
                self.login(with: id, name: name, video: video, completion: completion)
            }
        }
    }
    
    private func login(with id: String, name: String, video: Bool, completion: @escaping (Error?) -> Void) {
        apiService.getLoginInformation(for: id, and: name) { [weak self] result in
            if case .success (let loginInfo) = result {
                self?.authService.login(with: loginInfo.login, and: loginInfo.password) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    do {
                        try self?.conferenceService.joinConference(withID: id, sendVideo: video)
                        completion(nil)
                    } catch (let error) {
                        completion(error)
                    }
                }
            }
            if case .failure (let error) =  result {
                completion(error)
            }
        }
    }
}
