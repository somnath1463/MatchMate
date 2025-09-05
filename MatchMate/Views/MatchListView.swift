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
