//
//  MatchCardView.swift
//  MatchMate
//
//  Created by Somnath Mandhare on 04/09/25.
//

import Kingfisher
import SwiftUI

struct MatchCardView: View {
    let profile: UserProfileViewData
    let acceptAction: (String) -> Void
    let declineAction: (String) -> Void

    @State private var offset: CGFloat = 0
    @State private var isSwiping = false

    var statusText: String? {
        switch profile.status {
        case 1: return "Accepted"
        case 2: return "Declined"
        default: return nil
        }
    }

    var statusColor: Color {
        switch profile.status {
        case 1: return Color.green.opacity(0.2)
        case 2: return Color.red.opacity(0.2)
        default: return Color.clear
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                KFImage(URL(string: profile.pictureURL))
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 90, height: 110)
                    }
                    .retry(maxCount: 3, interval: .seconds(2))
                    .onFailure { error in
                        print("Image load failed: \(error)")
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(profile.firstName) \(profile.lastName)")
                        .font(.headline)
                    Text("\(profile.age) yrs • \(profile.city), \(profile.state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(profile.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            if let statusText = statusText {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(statusColor)
                    .cornerRadius(8)
            } else {
                HStack(spacing: 12) {
                    Button(action: {
                        print("[UI] Decline tapped for \(profile.id)")
                        declineAction(profile.id)
                    }) {
                        Text("Decline")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        print("[UI] Accept tapped for \(profile.id)")
                        acceptAction(profile.id)
                    }) {
                        Text("Accept")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .padding(.horizontal)
    }
}
