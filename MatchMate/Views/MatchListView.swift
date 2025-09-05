//
//  MatchListView.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import SwiftUI

struct MatchListView: View {
    @StateObject var viewModel = MatchListViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.profiles) { profile in
                    MatchCardView(
                        profile: profile,
                        acceptAction: viewModel.accept,
                        declineAction: viewModel.decline
                    )
                    .onAppear {
                        viewModel.fetchNextPageIfNeeded(currentItem: profile)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.plain)
            .buttonStyle(.plain)
            .navigationTitle("MatchMate")
            .toolbar {

                // Added toolbar item to clear the users from CoreData
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.clearAllUsers()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert(item: Binding(
                get: { viewModel.errorMessage.map { ErrorWrapper(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { wrapper in
                Alert(
                    title: Text("Error"),
                    message: Text(wrapper.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
