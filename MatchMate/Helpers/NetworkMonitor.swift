//
//  NetworkMonitor.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import Network
import Combine

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private(set) var isConnected = false
    let status = CurrentValueSubject<Bool, Never>(false)

    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            self.status.send(self.isConnected)
        }

        monitor.start(queue: queue)
    }
}
