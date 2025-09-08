//
//  PersistenceController.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 05/09/25.
//

import CoreData
import os

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    private let logger = Logger(subsystem: "com.matchmate", category: "Persistence")
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MatchMateModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("CoreData save error: \(error.localizedDescription)")
        }
    }
    
    func upsertUsers(_ users: [RandomUser], page: Int, completion: (() -> Void)? = nil) {
        let ctx = container.viewContext
        ctx.perform {
            for u in users {
                let fetch: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", u.login.uuid)
                fetch.fetchLimit = 1
                
                let profile = (try? ctx.fetch(fetch).first) ?? UserProfile(context: ctx)
                if profile.id == nil { profile.id = u.login.uuid }
                
                // update fields
                profile.firstName = u.name.first
                profile.lastName = u.name.last
                profile.email = u.email
                profile.age = Int16(u.dob.age)
                profile.city = u.location.city
                profile.state = u.location.state
                profile.country = u.location.country
                profile.pictureURL = u.picture.large
                profile.fetchedPage = Int16(page)
                if profile.createdAt == nil { profile.createdAt = Date() }
                if profile.status == 0 { profile.status = 0 } // default only for new users
            }
            
            do {
                try ctx.save()
                DispatchQueue.main.async { completion?() }
            } catch {
                self.logger.error("Save users failed for page \(page): \(error.localizedDescription)")
                DispatchQueue.main.async { completion?() }
            }
        }
    }

    func getMaxFetchedPage() -> Int {
        let ctx = container.viewContext
        let fetch = NSFetchRequest<NSDictionary>(entityName: "UserProfile")
        fetch.resultType = .dictionaryResultType
        fetch.propertiesToFetch = ["fetchedPage"]
        fetch.sortDescriptors = [NSSortDescriptor(key: "fetchedPage", ascending: false)]
        fetch.fetchLimit = 1
        if let result = try? ctx.fetch(fetch),
           let dict = result.first,
           let maxPage = dict["fetchedPage"] as? Int {
            return maxPage
        }
        return 0
    }

    func clearAllUsers(completion: (() -> Void)? = nil) {
        let ctx = container.viewContext
        ctx.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try ctx.execute(deleteRequest)
                try ctx.save()
                DispatchQueue.main.async { completion?() }
            } catch {
                self.logger.error("Failed to clear users: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?() }
            }
        }
    }
}
