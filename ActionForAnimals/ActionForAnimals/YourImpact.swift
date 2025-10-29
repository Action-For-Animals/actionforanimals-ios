//
//  YourImpact.swift
//  ActionForAnimals
//
//  Created by Claude on 10/27/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import SwiftUI
import OneSignal

struct YourImpact: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsAuthorized = false

    var totalActions: Int {
        store.totalAnimalsHelped
    }


    var weeklyStreak: Int {
        store.state.weeklyStreak
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with cow logo
                    HStack {
                        Text("Your Impact")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        Image(.afaStars)
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)

                    // Animals Helped Card
                    AnimalsHelpedCard(count: totalActions, message: getImpactMessage(for: totalActions))
                        .padding(.horizontal)

                    // Weekly Streak
                    WeeklyStreakSection(streak: weeklyStreak, hasActionThisWeek: hasActionThisWeek(), actionDays: getActionDaysThisWeek())
                        .padding(.horizontal)

                    // Achievements
                    AllAchievementsSection(notificationsAuthorized: notificationsAuthorized)
                        .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkNotificationPermission()
            }
        }
    }

    private func calculateWeeklyStreak() -> Int {
        // Calculate consecutive weeks with actions
        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var currentWeek = calendar.dateInterval(of: .weekOfYear, for: now)!

        while currentWeek.start > Date().addingTimeInterval(-365 * 24 * 60 * 60) { // Check last year
            let weekActions = store.state.issueCompletion.values.flatMap { $0 }.filter { action in
                currentWeek.contains(action.date)
            }

            if weekActions.isEmpty {
                break
            }

            streak += 1
            currentWeek = calendar.dateInterval(of: .weekOfYear, for: currentWeek.start.addingTimeInterval(-7 * 24 * 60 * 60))!
        }

        return streak
    }

    private func hasActionThisWeek() -> Bool {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)
        let now = Date()
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)!

        return store.state.issueCompletion.values.flatMap { $0 }.contains { action in
            thisWeek.contains(action.date)
        }
    }

    private func getActionDaysThisWeek() -> Set<Int> {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)
        let now = Date()
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)!

        let actionsThisWeek = store.state.issueCompletion.values.flatMap { $0 }.filter { action in
            thisWeek.contains(action.date)
        }

        return Set(actionsThisWeek.map { action in
            // Convert to 0-based Monday start (0 = Monday, 6 = Sunday)
            let weekday = calendar.component(.weekday, from: action.date)
            return weekday == 1 ? 6 : weekday - 2 // Sunday = 6, Monday-Saturday = 0-5
        })
    }

    private func getImpactMessage(for count: Int) -> String {
        switch count {
        case 0:
            return "Ready to make your first impact?"
        case 1...10:
            return "Every action makes a difference"
        case 11...100:
            return "You've helped an entire sanctuary"
        case 101...500:
            return "You're changing the world for animals"
        default: // 501+
            return "You're an animal advocacy champion"
        }
    }

    private func checkNotificationPermission() {
        // Check OneSignal permission status
        let deviceState = OneSignal.getDeviceState()
        notificationsAuthorized = deviceState?.hasNotificationPermission ?? false
    }

}

enum AchievementCategory {
    case action
    case animal
    case milestone
    case settings
}

struct Achievement {
    let title: String
    let subtitle: String
    let compactSubtitle: String
    let icon: String
    let category: AchievementCategory
    let isUnlocked: Bool
}

struct AnimalsHelpedCard: View {
    let count: Int
    let message: String

    var body: some View {
        ZStack {
            // Background image
            Image("sanctuary")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Text positioned in upper area
            VStack {
                VStack(spacing: 0) {
                    Text("Animals Helped")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        Text("\(count)")
                            .font(.system(size: 56, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)

                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .padding(.top, -5)
                    }
                    .padding(.top, -15)
                }
                .padding(.top, 30)

                Spacer()
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .clipped()
    }
}

struct WeeklyStreakSection: View {
    let streak: Int
    let hasActionThisWeek: Bool
    let actionDays: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Streak")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: 4) {
                    Image("badge-hot-streak")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text("\(streak)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("This Week")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer()

                    if hasActionThisWeek {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Action completed")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }

                // Weekly calendar
                WeeklyCalendarView(actionDays: actionDays)
            }
        }
    }
}

struct WeeklyCalendarView: View {
    let actionDays: Set<Int>

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    private let today: Int = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 ? 6 : weekday - 2 // Sunday = 6, Monday-Saturday = 0-5
    }()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                Text(weekdays[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(actionDays.contains(index) ? Color.afaGreen : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(actionDays.contains(index) ? .white : .primary)
                    .overlay(
                        // Add a subtle border for today
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(index == today ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
            Spacer()
        }
    }
}

struct AllAchievementsSection: View {
    @EnvironmentObject var store: Store
    let notificationsAuthorized: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ActionAchievementsSection(notificationsAuthorized: notificationsAuthorized)
            AnimalAchievementsSection()
            MilestoneAchievementsSection()
        }
    }
}

struct ActionAchievementsSection: View {
    @EnvironmentObject var store: Store
    let notificationsAuthorized: Bool


    private var achievements: [Achievement] {
        let actionAchievements = AchievementRegistry.achievementsByCategory(.action)
        let settingsAchievements = AchievementRegistry.achievementsByCategory(.settings)

        return (actionAchievements + settingsAchievements)
            .map { AchievementRegistry.createAchievement(from: $0, store: store) }
            .sorted { $0.isUnlocked && !$1.isUnlocked }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Action Achievements")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(achievements.filter(\.isUnlocked).count) of \(achievements.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(achievements, id: \.title) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct AnimalAchievementsSection: View {
    @EnvironmentObject var store: Store


    private var achievements: [Achievement] {
        return AchievementRegistry.achievementsByCategory(.animal)
            .map { AchievementRegistry.createAchievement(from: $0, store: store) }
            .sorted { $0.isUnlocked && !$1.isUnlocked }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Animal Achievements")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(achievements.filter(\.isUnlocked).count) of \(achievements.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(achievements, id: \.title) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MilestoneAchievementsSection: View {
    @EnvironmentObject var store: Store


    private var achievements: [Achievement] {
        return AchievementRegistry.achievementsByCategory(.milestone)
            .map { AchievementRegistry.createAchievement(from: $0, store: store) }
            .sorted { $0.isUnlocked && !$1.isUnlocked }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Milestone Achievements")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(achievements.filter(\.isUnlocked).count) of \(achievements.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(achievements, id: \.title) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}


struct AchievementCard: View {
    let achievement: Achievement


    var body: some View {
        VStack(spacing: 0) {
            // Fixed icon section
            ZStack {
                // Larger centered icon - either image asset or emoji
                if achievement.icon.hasPrefix("badge-") {
                    Image(achievement.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else {
                    Text(achievement.icon)
                        .font(.system(size: 60))
                }

                // Lock icon in top-right corner (if not unlocked)
                if !achievement.isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 116, height: 75)

            // Fixed text section
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? .primary : .gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(achievement.compactSubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 116, height: 58)
        }
        .padding(12)
        .frame(width: 140, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.white : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievement.isUnlocked ? Color.afaGreen : Color.gray.opacity(0.3), lineWidth: achievement.isUnlocked ? 2 : 1)
                )
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

struct YourImpact_Previews: PreviewProvider {
    static let previewState = {
        var state = AppState()
        state.issues = [
            AnimalPolicy.basicPreviewIssue,
            AnimalPolicy.multilinePreviewIssue
        ]

        // Add some mock completion data
        state.issueCompletion = [
            1: [
                ContactLog(issueId: "1", contactId: "contact1", phone: "", outcome: "contacted", date: Date().addingTimeInterval(-86400), reported: true, actionType: "call", animalsHelped: 2, category: "farmed"),
                ContactLog(issueId: "1", contactId: "contact2", phone: "", outcome: "voicemail", date: Date().addingTimeInterval(-172800), reported: true, actionType: "call", animalsHelped: 2, category: "farmed")
            ],
            2: [
                ContactLog(issueId: "2", contactId: "contact3", phone: "", outcome: "email_sent", date: Date().addingTimeInterval(-259200), reported: true, actionType: "email", animalsHelped: 3, category: "wildlife")
            ]
        ]

        return state
    }()

    static let store = Store(state: previewState, middlewares: [appMiddleware()])

    static var previews: some View {
        YourImpact()
            .environmentObject(store)
    }
}