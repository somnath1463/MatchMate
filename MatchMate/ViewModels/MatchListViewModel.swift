//
//  MatchListViewModel.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import Foundation
import Combine
import CoreData
import os

enum UserStatus: Int16 {
    case none = 0
    case accepted = 1
    case declined = 2
}

final class MatchListViewModel: ObservableObject {

    // MARK: - Published properties (UI binding)
    @Published private(set) var profiles: [UserProfileViewData] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var hasMorePages = true

    // MARK: - Private state
    private var currentPage = 1
    private let pageSize = 10
    private var cancellables = Set<AnyCancellable>()
    private var updatingIds = Set<String>()
    private let updateLockQueue = DispatchQueue(label: "MatchListViewModel.updateLock")
    private let logger = Logger(subsystem: "com.matchmate", category: "MatchListViewModel")

    // MARK: - Dependencies
    private let persistence: PersistenceController
    private let api: APIServiceProtocol
    private let syncService: SyncService

    // MARK: - Init
    init(
        persistence: PersistenceController = .shared,
        api: APIServiceProtocol = APIService.shared,
        syncService: SyncService = SyncService()
    ) {
        self.persistence = persistence
        self.api = api
        self.syncService = syncService
        
        loadCachedProfiles()
        let lastPage = persistence.getMaxFetchedPage()
        currentPage = lastPage > 0 ? lastPage : 1
        fetchPage(currentPage)
    }

    deinit {
        logger.debug("MatchListViewModel deinitialized, cancelling subscriptions")
    }

    // MARK: - Data loading

    func loadCachedProfiles() {
        let ctx = persistence.container.viewContext
        let fetch: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let results = try ctx.fetch(fetch)
            self.profiles = results.map { UserProfileViewData(managedObject: $0) }
        } catch {
            logger.error("CoreData fetch error: \(error.localizedDescription)")
        }
    }

    func fetchPage(_ page: Int) {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        api.fetchUsers(page: page, results: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] comp in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let err) = comp {
                    self.errorMessage = err.localizedDescription
                    self.logger.error("Fetch users failed: \(err.localizedDescription)")
                }
            }, receiveValue: { [weak self] users in
                guard let self else { return }
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
        updateStatus(userId: userId, status: .accepted)
    }

    func decline(_ userId: String) {
        updateStatus(userId: userId, status: .declined)
    }

    private func updateStatus(userId: String, status: UserStatus) {
        guard acquireUpdateLock(for: userId) else {
            logger.debug("Ignoring duplicate update for \(userId) -> \(status.rawValue)")
            return
        }
        
        // 1) Update in-memory model immediately so UI reflects change
        DispatchQueue.main.async {
            if let idx = self.profiles.firstIndex(where: { $0.id == userId }) {
                self.profiles[idx] = self.profiles[idx].copy(withStatus: status.rawValue)
                self.logger.debug("Updated in-memory profiles for \(userId) -> \(status.rawValue)")
            }
        }
        
        // 2) Persist in Core Data on background context
        let ctx = persistence.container.newBackgroundContext()
        ctx.perform {
            let fetch: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", userId)
            
            do {
                if let profile = try ctx.fetch(fetch).first {
                    profile.status = status.rawValue
                    try ctx.save()
                    self.logger.debug("Persisted \(userId) -> \(status.rawValue) to CoreData")
                } else {
                    self.logger.warning("No CoreData profile found for \(userId)")
                }
            } catch {
                self.logger.error("Update status error for \(userId): \(error.localizedDescription)")
            }
            
            // Offline sync if network unavailable
            if NetworkMonitor.shared.isConnected {
                self.logger.debug("Network available — would sync to server for \(userId)")
            } else {
                self.syncService.queueAction(userId: userId, status: status.rawValue)
                self.logger.debug("Network unavailable — queued action for \(userId) -> \(status.rawValue)")
            }
            
            // Release lock
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.releaseUpdateLock(for: userId)
            }
        }
    }

    // MARK: - Helpers

    private func acquireUpdateLock(for id: String) -> Bool {
        var proceed = false
        updateLockQueue.sync {
            if !updatingIds.contains(id) {
                updatingIds.insert(id)
                proceed = true
            }
        }
        return proceed
    }

    private func releaseUpdateLock(for id: String) {
        _ = updateLockQueue.sync {
            updatingIds.remove(id)
        }

        logger.debug("Released updating lock for \(id)")
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

// MARK: - UserProfileViewData extension
extension UserProfileViewData {
    func copy(withStatus status: Int16) -> UserProfileViewData {
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
            status: UserStatus(rawValue: status) ?? .none
        )
    }
}
