//
//  RandomUserResponse.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import Foundation

struct RandomUserResponse: Codable {
    let results: [RandomUser]
    let info: Info
}

struct RandomUser: Codable {
    let login: Login
    let name: Name
    let email: String
    let dob: DOB
    let location: Location
    let picture: Picture

    struct Login: Codable {
        let uuid: String
    }

    struct Name: Codable {
        let title: String
        let first: String
        let last: String
    }

    struct DOB: Codable {
        let date: String
        let age: Int
    }

    struct Location: Codable {
        let city: String
        let state: String
        let country: String
    }

    struct Picture: Codable {
        let large: String
        let medium: String
        let thumbnail: String
    }
}

struct Info: Codable {
    let seed: String?
    let results: Int?
    let page: Int?
    let version: String?
}
