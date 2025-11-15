//
//  LeaderboardComponents.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

// MARK: - Data Models
struct LeagueParticipant: Codable, Identifiable, Equatable {
    var id: String { callerid }
    let callerid: String
    let nickname: String
    let location: String?
    let avatar: String
    let animalsHelped: Int
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case callerid, nickname, location, avatar, animalsHelped, rank
    }

    static func == (lhs: LeagueParticipant, rhs: LeagueParticipant) -> Bool {
        return lhs.callerid == rhs.callerid &&
               lhs.nickname == rhs.nickname &&
               lhs.location == rhs.location &&
               lhs.avatar == rhs.avatar &&
               lhs.animalsHelped == rhs.animalsHelped &&
               lhs.rank == rhs.rank
    }
}

struct LeagueMeta: Codable {
    let totalAnimals: Int
    let participantCount: Int
    let month: String?
}

// MARK: - Rank Badge Component
struct RankBadge: View {
    let rank: Int

    var body: some View {
        ZStack {
            if rank <= 3 {
                // Medal image
                Image(medalImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                // Regular number
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var medalImageName: String {
        switch rank {
        case 1: return "gold-medal"
        case 2: return "silver-medal"
        case 3: return "bronze-medal"
        default: return ""
        }
    }
}

// MARK: - Leaderboard Row Component
struct LeaderboardRow: View {
    let participant: LeagueParticipant
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            RankBadge(rank: participant.rank)

            // User avatar
            Image(participant.avatar)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.gray.opacity(0.1)))
                .clipShape(Circle())

            // Nickname and location
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.nickname)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let location = participant.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Animals helped count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(participant.animalsHelped)")
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
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Total Animals Circle Component
struct TotalAnimalsCircle: View {
    let totalAnimals: Int?
    let showEmptyState: Bool

    init(totalAnimals: Int? = nil, showEmptyState: Bool = false) {
        self.totalAnimals = totalAnimals
        self.showEmptyState = showEmptyState
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer border (vivid green)
                Circle()
                    .fill(Color(red: 0.0, green: 0.8, blue: 0.0))
                    .frame(width: 262, height: 262)

                // Middle border (white) - 2px
                Circle()
                    .fill(Color.white)
                    .frame(width: 259, height: 259)

                // Inner border (medium dark green) - keeping original thickness
                Circle()
                    .fill(Color(red: 0.0, green: 0.6, blue: 0.0))
                    .frame(width: 255, height: 255)

                // Main circle (white)
                Circle()
                    .fill(Color.white)
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                if showEmptyState {
                    // Show large animals-high-five image filling most of the circle
                    Image("animals-high-five")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                } else {
                    VStack(spacing: 0) {
                        Image("animals-high-five")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .padding(.bottom, 16)

                        Text("Animals Helped")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            if let totalAnimals = totalAnimals {
                                Text("\(totalAnimals)")
                                    .font(.system(size: 72, weight: .bold, design: .default))
                                    .foregroundColor(Color(red: 0.0, green: 0.6, blue: 0.0))
                            } else {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color(red: 0.0, green: 0.6, blue: 0.0))
                            }

                            Text("Together")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.0, green: 0.6, blue: 0.0))
                                .padding(.top, -8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Previous Winners Carousel
struct PreviousWinnersCarousel: View {
    let winners: [LeagueParticipant]
    let monthName: String

    var body: some View {
        VStack(spacing: 16) {
            Text("\(monthName) Winners 🏆")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if winners.isEmpty {
                Text("No previous winners yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                HStack(spacing: 20) {
                    ForEach(winners.prefix(3), id: \.callerid) { winner in
                        VStack(spacing: 8) {
                            ZStack {
                                // Medal image as background
                                Image(medalImageNameForRank(winner.rank))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)

                                // User avatar (smaller and centered)
                                Image(winner.avatar)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }

                            Text(winner.nickname)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Text("\(winner.animalsHelped)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .frame(width: 80)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func medalImageNameForRank(_ rank: Int) -> String {
        switch rank {
        case 1: return "gold-medal"
        case 2: return "silver-medal"
        case 3: return "bronze-medal"
        default: return ""
        }
    }
}

// MARK: - Empty State Component
struct LeagueEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Sample participants for preview
        let sampleParticipants = [
            LeagueParticipant(callerid: "1", nickname: "AnimalLover", location: "Austin, TX", avatar: "badge-wildlife", animalsHelped: 87, rank: 1),
            LeagueParticipant(callerid: "2", nickname: "FoxFriend", location: "Portland, OR", avatar: "badge-entertainment", animalsHelped: 78, rank: 2),
            LeagueParticipant(callerid: "3", nickname: "CompanionCare", location: nil, avatar: "badge-wildlife", animalsHelped: 65, rank: 3)
        ]

        TotalAnimalsCircle(totalAnimals: 1250)

        ForEach(sampleParticipants, id: \.callerid) { participant in
            LeaderboardRow(participant: participant, isCurrentUser: participant.rank == 2)
        }

        PreviousWinnersCarousel(winners: sampleParticipants, monthName: "October")
    }
    .padding()
}