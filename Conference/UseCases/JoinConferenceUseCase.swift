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
    private let permissionsService: PermissionsService
    
    required init(authService: AuthService, conferenceService: ConferenceService, apiService: VoximplantAPIService, permissionsService: PermissionsService) {
        self.authService = authService
        self.conferenceService = conferenceService
        self.apiService = apiService
        self.permissionsService = permissionsService
    }
    
    func execute(withId id: String, andName name: String, sendVideo video: Bool, completion: @escaping (Error?) -> Void) {
        requestPermissions(includingVideo: video) { error in
            if let error = error {
                completion(error)
            } else {
                self.login(with: id, name: name, video: video, completion: completion)
            }
        }
    }
    
    private func requestPermissions(includingVideo video: Bool, completion: @escaping (Error?) -> Void) {
        permissionsService.requestPermissions(for: .audio) { granted in
            if granted {
                if video {
                    self.permissionsService.requestPermissions(for: .video) { granted in
                        completion(granted ? nil : Errors.videoPermissionsDenied)
                    }
                    return
                }
                completion(nil)
            } else {
                completion(Errors.audioPermissionsDenied)
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
