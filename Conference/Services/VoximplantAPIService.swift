/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct LoginInformation: Decodable {
    let login, password: String
}

final class VoximplantAPIService {
    private let host = "https://demos05.voximplant.com/conf/api/"
    
    func getLoginInformation(
        for id: String,
        and displayName: String,
        completion: @escaping (Result<LoginInformation, Error>) -> Void
    ) {
        guard let displayName = displayName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            else {
                completion(.failure(Errors.unsupportedName))
                return
        }
        guard let url = URL(string:"\(host)?id=\(id)&displayName=\(displayName)&email=&conferenceId=\(id)")
            else {
                completion(.failure(Errors.failedToBuildURL))
                return
        }
        
        executeRequest(with: url) { result in
            if case .success (let data) = result {
                do {
                    let loginInformation = try JSONDecoder().decode(LoginInformation.self, from: data)
                    completion(.success(loginInformation))
                } catch (let error) {
                    completion(.failure(error))
                }
            }
            if case .failure (let error) = result { completion(.failure(error)) }
        }
    }
    
    private func executeRequest(with url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(Errors.noDataReceived))
            }
        }.resume()
    }
}
