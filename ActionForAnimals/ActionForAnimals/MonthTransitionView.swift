//
//  MonthTransitionView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-12.
//

import SwiftUI

struct MonthTransitionData {
    let month: String
    let totalAnimals: Int
    let totalParticipants: Int
    let winners: [Winner]
    let userStats: UserStats?

    struct Winner {
        let rank: Int
        let nickname: String
        let animalsHelped: Int
        let avatar: String
    }

    struct UserStats {
        let rank: Int
        let animalsHelped: Int
        let totalParticipants: Int
    }
}

struct MonthTransitionView: View {
    let data: MonthTransitionData?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration image
                    Image("animals-high-five")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .padding(.top, 40)

                VStack(spacing: 16) {
                    Text(monthDisplayName(data?.month))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let data = data {
                        // Community impact
                        VStack(spacing: 8) {
                            Text("Together we saved")
                                .font(.title3)
                                .foregroundColor(.secondary)

                            Text("\(data.totalAnimals) animals")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }

                        // Personal stats
                        if let userStats = data.userStats {
                            Text("You ranked #\(userStats.rank) of \(userStats.totalParticipants) advocates")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Winners
                        if !data.winners.isEmpty {
                            VStack(spacing: 0) {
                                VStack(spacing: 16) {
                                    Text("Top Advocates")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    LazyVStack(spacing: 8) {
                                        ForEach(data.winners, id: \.rank) { winner in
                                            HStack(spacing: 12) {
                                                // Medal or rank
                                                if winner.rank <= 3 {
                                                    Image(medalImageName(for: winner.rank - 1))
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 32, height: 32)
                                                } else {
                                                    Text("\(winner.rank)")
                                                        .font(.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                        .frame(width: 32, height: 32)
                                                }

                                                // Avatar
                                                Image(winner.avatar)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 40, height: 40)
                                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                                                    .clipShape(Circle())

                                                // Name
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(winner.nickname)
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                }

                                                Spacer()

                                                // Animals helped count (right-aligned)
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("\(winner.animalsHelped)")
                                                        .font(.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.green)

                                                    Text("animals")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(.systemBackground))
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                            }
                        }
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading results...")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    }
                }

                // Button with proper padding for small screens
                // No join button - user needs to take an action first
                Spacer(minLength: 30)
            }
        }
            .navigationTitle("Month Transition")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
            }
        }
    }

    private func medalImageName(for index: Int) -> String {
        switch index {
        case 0: return "gold-medal"
        case 1: return "silver-medal"
        case 2: return "bronze-medal"
        default: return ""
        }
    }

    private func monthDisplayName(_ monthKey: String?) -> String {
        guard let monthKey = monthKey else { return "November Results" }

        let components = monthKey.split(separator: "-")
        guard components.count == 2,
              let month = Int(components[1]) else {
            return "Previous Month Results"
        }

        let monthNames = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]

        if month >= 1 && month <= 12 {
            return "\(monthNames[month - 1]) Results"
        }

        return "Previous Month Results"
    }
}

#Preview {
    let sampleData = MonthTransitionData(
        month: "2024-11",
        totalAnimals: 156,
        totalParticipants: 23,
        winners: [
            MonthTransitionData.Winner(rank: 1, nickname: "John Doe", animalsHelped: 25, avatar: "lion_avatar"),
            MonthTransitionData.Winner(rank: 2, nickname: "Jane Smith", animalsHelped: 18, avatar: "cat_avatar"),
            MonthTransitionData.Winner(rank: 3, nickname: "Bob Johnson", animalsHelped: 15, avatar: "dog_avatar")
        ],
        userStats: MonthTransitionData.UserStats(rank: 8, animalsHelped: 12, totalParticipants: 23)
    )

    MonthTransitionView(data: sampleData)
        .environmentObject(Store(state: AppState()))
}