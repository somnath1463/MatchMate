//
//  MatchMateApp.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import SwiftUI

@main
struct MatchMateApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MatchListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
