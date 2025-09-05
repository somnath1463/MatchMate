//
//  MatchListViewModel.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import Foundation
import Combine
import CoreData

final class MatchListViewModel: ObservableObject {

    // Published properties for UI binding
    @Published var profiles: [UserProfileViewData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true

    // Private state
    private var currentPage = 1
    private let pageSize = 10
    private var cancellables = Set<AnyCancellable>()

    // Dependencies
    private let persistence = PersistenceController.shared
    private let api = APIService.shared
    private let syncService = SyncService()
    private var updatingIds = Set<String>()           // track currently-updating items
    private let updateLockQueue = DispatchQueue(label: "MatchListViewModel.updateLock")

    init() {
        loadCachedProfiles()
        let lastPage = persistence.getMaxFetchedPage()
        currentPage = lastPage > 0 ? lastPage : 1
        fetchPage(currentPage)
    }

    // MARK: - Data loading

    func loadCachedProfiles() {
        let ctx = persistence.container.viewContext
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        fetch.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let results = try ctx.fetch(fetch)
            self.profiles = results.map { UserProfileViewData(managedObject: $0) }
            for profile in results {
                if let id = profile.value(forKey: "id") as? String,
                   let st = (profile.value(forKey: "status") as? NSNumber)?.int16Value {
                    print("Fetched profile \(id) has status \(st)")
                }
            }
        } catch {
            print("CoreData fetch error: \(error)")
        }
    }

    func fetchPage(_ page: Int) {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        api.fetchUsers(page: page, results: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] comp in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let err) = comp {
                    self.errorMessage = err.localizedDescription
                }
            }, receiveValue: { [weak self] users in
                guard let self = self else { return }
                if users.isEmpty {
                    self.hasMorePages = false
                    return
                }

                self.persistence.upsertUsers(users, page: page) {
                    self.loadCachedProfiles()
                    self.currentPage = page
                }
            })
            .store(in: &cancellables)
    }

    func fetchNextPageIfNeeded(currentItem: UserProfileViewData?) {
        guard let item = currentItem else { return }
        if profiles.last?.id == item.id {
            fetchPage(currentPage + 1)
        }
    }

    // MARK: - Accept / Decline

    func accept(_ userId: String) {
        print("[VM] accept() called for \(userId)")
        updateStatus(userId: userId, status: 1)
    }
    func decline(_ userId: String) {
        print("[VM] decline() called for \(userId)")
        updateStatus(userId: userId, status: 2)
    }

    private func updateStatus(userId: String, status: Int16) {
        // Prevent simultaneous updates for same id
        var shouldProceed = false
        updateLockQueue.sync {
            if !updatingIds.contains(userId) {
                updatingIds.insert(userId)
                shouldProceed = true
            }
        }

        guard shouldProceed else {
            print("[VM] Ignoring duplicate update for \(userId) -> \(status)")
            return
        }

        // 1) Update in-memory model immediately so UI reflects change
        DispatchQueue.main.async {
            if let idx = self.profiles.firstIndex(where: { $0.id == userId }) {
                var copy = self.profiles[idx]
                copy = UserProfileViewData(
                    id: copy.id,
                    firstName: copy.firstName,
                    lastName: copy.lastName,
                    email: copy.email,
                    age: copy.age,
                    city: copy.city,
                    state: copy.state,
                    country: copy.country,
                    pictureURL: copy.pictureURL,
                    status: status
                )
                self.profiles[idx] = copy
                print("[VM] In-memory profiles updated for \(userId) -> \(status)")
            }
        }

        // 2) Persist in Core Data on background context
        let ctx = persistence.container.viewContext
        ctx.perform {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
            fetch.predicate = NSPredicate(format: "id == %@", userId)
            do {
                if let profiles = try ctx.fetch(fetch) as? [NSManagedObject],
                   let profile = profiles.first {
                    profile.setValue(status, forKey: "status")
                    try ctx.save()
                    print("[VM] Persisted \(userId) -> \(status) to CoreData")
                } else {
                    print("[VM] No CoreData profile found for \(userId) when persisting status")
                }
            } catch {
                print("[VM] Update status error: \(error)")
            }

            // queue offline sync if needed
            if NetworkMonitor.shared.isConnected {
                // call server when available (no-op for randomuser demo)
                print("[VM] Network available — would sync to server for \(userId)")
            } else {
                self.syncService.queueAction(userId: userId, status: status)
                print("[VM] Network unavailable — queued pending action for \(userId) -> \(status)")
            }

            // release lock after small delay to avoid race conditions / double-fire
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.updateLockQueue.sync {
                    self.updatingIds.remove(userId)
                }
                print("[VM] Released updating lock for \(userId)")
            }
        }
    }

    func clearAllUsers() {
        persistence.clearAllUsers {
            DispatchQueue.main.async {
                self.profiles.removeAll()
                self.currentPage = 1
                self.hasMorePages = true
                self.fetchPage(1)
            }
        }
    }
}
