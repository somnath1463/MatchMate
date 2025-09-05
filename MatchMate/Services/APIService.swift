//
//  APIService.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 05/09/25.
//

import Foundation
import Combine

final class APIService {
    static let shared = APIService()
    private init() {}

    func fetchUsers(page: Int = 1, results: Int = 10) -> AnyPublisher<[RandomUser], Error> {
        var comps = URLComponents(string: "https://randomuser.me/api/")!
        comps.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "results", value: "\(results)"),
            URLQueryItem(name: "seed", value: "matchmate")
        ]
        let request = URLRequest(url: comps.url!)
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                    throw URLError(.badServerResponse)
                }

                return data
            }
            .decode(type: RandomUserResponse.self, decoder: JSONDecoder())
            .map { $0.results }
            .eraseToAnyPublisher()
    }
}
