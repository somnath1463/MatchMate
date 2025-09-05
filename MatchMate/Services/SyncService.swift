//
//  SyncService.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 05/09/25.
//

import CoreData
import Combine

final class SyncService {
    private let persistence: PersistenceController
    private var cancellable: AnyCancellable?

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        cancellable = NetworkMonitor.shared.status
            .sink { [weak self] isConnected in
                if isConnected { self?.processPendingActions() }
            }
    }

    func queueAction(userId: String, status: Int16) {
        let ctx = persistence.container.viewContext
        ctx.perform {
            let ent = NSEntityDescription.insertNewObject(forEntityName: "PendingAction", into: ctx)
            ent.setValue(UUID(), forKey: "id")
            ent.setValue(userId, forKey: "userId")
            ent.setValue(status, forKey: "status")
            ent.setValue(Date(), forKey: "createdAt")
            do { try ctx.save() } catch { print("Queue action failed: \(error)") }
        }
    }

    private func processPendingActions() {
        let ctx = persistence.container.viewContext
        ctx.perform {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "PendingAction")
            do {
                let actions = try ctx.fetch(fetch)
                for action in actions {
                    guard let userId = action.value(forKey: "userId") as? String,
                          let status = action.value(forKey: "status") as? Int16 else { continue }
                    // For this fake API we can't send actions upstream.
                    // For real API: call APIService to sync this decision.
                    // We'll apply the action locally (mark user profile) and then delete pending action.
                    let profileFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
                    profileFetch.predicate = NSPredicate(format: "id == %@", userId)
                    if let profiles = try ctx.fetch(profileFetch) as? [NSManagedObject],
                       let profile = profiles.first {
                        profile.setValue(status, forKey: "status")
                    }
                    ctx.delete(action) // remove pending action once applied
                }
                try ctx.save()
            } catch {
                print("Processing pending actions failed: \(error)")
            }
        }
    }
}

