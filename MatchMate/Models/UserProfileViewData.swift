//
//  UserProfileViewData.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import Foundation
import CoreData

struct UserProfileViewData: Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let age: Int
    let city: String
    let state: String
    let country: String
    let pictureURL: String
    let status: UserStatus
    
    // MARK: - Init from CoreData model
    init(managedObject: UserProfile) {
        self.id = managedObject.id ?? UUID().uuidString
        self.firstName = managedObject.firstName ?? ""
        self.lastName = managedObject.lastName ?? ""
        self.email = managedObject.email ?? ""
        self.age = Int(managedObject.age)
        self.city = managedObject.city ?? ""
        self.state = managedObject.state ?? ""
        self.country = managedObject.country ?? ""
        self.pictureURL = managedObject.pictureURL ?? ""
        self.status = UserStatus(rawValue: managedObject.status) ?? .none
    }
    
    // MARK: - Manual init
    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        age: Int,
        city: String,
        state: String,
        country: String,
        pictureURL: String,
        status: UserStatus
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.age = age
        self.city = city
        self.state = state
        self.country = country
        self.pictureURL = pictureURL
        self.status = status
    }
    
    // MARK: - Helpers
    func copy(withStatus status: UserStatus) -> UserProfileViewData {
        UserProfileViewData(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            age: age,
            city: city,
            state: state,
            country: country,
            pictureURL: pictureURL,
            status: status
        )
    }
}
