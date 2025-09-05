//
//  PersistenceController.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 05/09/25.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

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
        if context.hasChanges {
            do { try context.save() } catch {
                print("CoreData save error: \(error)")
            }
        }
    }

    func upsertUsers(_ users: [RandomUser], page: Int, completion: (() -> Void)? = nil) {
        let ctx = container.viewContext
        ctx.perform {
            print("[CoreData] Upserting \(users.count) users for page \(page)")

            for u in users {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
                fetch.predicate = NSPredicate(format: "id == %@", u.login.uuid)
                fetch.fetchLimit = 1

                if let existing = (try? ctx.fetch(fetch))?.first as? NSManagedObject {
                    // Preserve existing status
                    let currentStatus = existing.value(forKey: "status") as? Int16 ?? 0

                    existing.setValue(u.name.first, forKey: "firstName")
                    existing.setValue(u.name.last, forKey: "lastName")
                    existing.setValue(u.email, forKey: "email")
                    existing.setValue(Int16(u.dob.age), forKey: "age")
                    existing.setValue(u.location.city, forKey: "city")
                    existing.setValue(u.location.state, forKey: "state")
                    existing.setValue(u.location.country, forKey: "country")
                    existing.setValue(u.picture.large, forKey: "pictureURL")
                    existing.setValue(Int16(page), forKey: "fetchedPage")
                    existing.setValue(currentStatus, forKey: "status")   // ✅ keep existing status

                    print("[CoreData] Updated existing user \(u.login.uuid) page=\(page) status=\(currentStatus)")
                } else {
                    let ent = NSEntityDescription.insertNewObject(forEntityName: "UserProfile", into: ctx)
                    ent.setValue(u.login.uuid, forKey: "id")
                    ent.setValue(u.name.first, forKey: "firstName")
                    ent.setValue(u.name.last, forKey: "lastName")
                    ent.setValue(u.email, forKey: "email")
                    ent.setValue(Int16(u.dob.age), forKey: "age")
                    ent.setValue(u.location.city, forKey: "city")
                    ent.setValue(u.location.state, forKey: "state")
                    ent.setValue(u.location.country, forKey: "country")
                    ent.setValue(u.picture.large, forKey: "pictureURL")
                    ent.setValue(Int16(0), forKey: "status")   // default only for new users
                    ent.setValue(Date(), forKey: "createdAt")
                    ent.setValue(Int16(page), forKey: "fetchedPage")

                    print("[CoreData] Inserted NEW user \(u.login.uuid) page=\(page)")
                }
            }

            do {
                try ctx.save()
                print("[CoreData] Save successful for page \(page)")
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("[CoreData] Save users failed for page \(page): \(error)")
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
}

// MARK: Pagination Helper

extension PersistenceController {
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
}

// MARK: - Deletion of CoreData Users

extension PersistenceController {
    func clearAllUsers(completion: (() -> Void)? = nil) {
        let ctx = container.viewContext
        ctx.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try ctx.execute(deleteRequest)
                try ctx.save()
                print("[CoreData] Cleared all UserProfile records")
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("[CoreData] Failed to clear users: \(error)")
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
}
