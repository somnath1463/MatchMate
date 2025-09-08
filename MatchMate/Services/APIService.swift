//
//  APIService.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 05/09/25.
//

import Foundation
import Combine

protocol APIServiceProtocol {
    func fetchUsers(page: Int, results: Int) -> AnyPublisher<[RandomUser], Error>
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()
    private init() {}
    
    func fetchUsers(page: Int = 1, results: Int = 10) -> AnyPublisher<[RandomUser], Error> {
        guard var comps = URLComponents(string: "https://randomuser.me/api/") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        comps.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "results", value: "\(results)"),
            URLQueryItem(name: "seed", value: "matchmate")
        ]
        
        guard let url = comps.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: RandomUserResponse.self, decoder: decoder)
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
