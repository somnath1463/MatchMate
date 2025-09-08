//
//  SyncService.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 05/09/25.
//

import CoreData
import Combine
import os

final class SyncService {
    private let persistence: PersistenceController
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.matchmate", category: "SyncService")
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        NetworkMonitor.shared.status
            .sink { [weak self] isConnected in
                if isConnected { self?.processPendingActions() }
            }
            .store(in: &cancellables)
    }
    
    func queueAction(userId: String, status: Int16) {
        let ctx = persistence.container.viewContext
        ctx.perform {
            let action = PendingAction(context: ctx) // ✅ Use generated NSManagedObject subclass
            action.id = UUID()
            action.userId = userId
            action.status = status
            action.createdAt = Date()
            
            do {
                try ctx.save()
            } catch {
                self.logger.error("Queue action failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func processPendingActions() {
        let ctx = persistence.container.viewContext
        ctx.perform {
            let fetch: NSFetchRequest<PendingAction> = PendingAction.fetchRequest()
            do {
                let actions = try ctx.fetch(fetch)
                for action in actions {
                    if let userId = action.userId {
                        let profileFetch: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
                        profileFetch.predicate = NSPredicate(format: "id == %@", userId)
                        if let profile = try ctx.fetch(profileFetch).first {
                            profile.status = action.status
                        }
                    }
                    ctx.delete(action)
                }
                try ctx.save()
            } catch {
                self.logger.error("Processing pending actions failed: \(error.localizedDescription)")
            }
        }
    }
}

