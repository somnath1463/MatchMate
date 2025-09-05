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
    let status: Int16

    init(managedObject: NSManagedObject) {
        self.id = managedObject.value(forKey: "id") as? String ?? UUID().uuidString
        self.firstName = managedObject.value(forKey: "firstName") as? String ?? ""
        self.lastName = managedObject.value(forKey: "lastName") as? String ?? ""
        self.email = managedObject.value(forKey: "email") as? String ?? ""
        self.age = Int(managedObject.value(forKey: "age") as? Int16 ?? 0)
        self.city = managedObject.value(forKey: "city") as? String ?? ""
        self.state = managedObject.value(forKey: "state") as? String ?? ""
        self.country = managedObject.value(forKey: "country") as? String ?? ""
        self.pictureURL = managedObject.value(forKey: "pictureURL") as? String ?? ""
        self.status = (managedObject.value(forKey: "status") as? NSNumber)?.int16Value ?? 0
    }

    init(id: String,
         firstName: String,
         lastName: String,
         email: String,
         age: Int, city:
         String,
         state: String,
         country: String,
         pictureURL: String,
         status: Int16) {
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
}
