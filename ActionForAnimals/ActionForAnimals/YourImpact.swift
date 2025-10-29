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

    // Helper function to get category for a log with lazy loading
    private func getCategory(for log: ContactLog) -> String {
        if let category = log.category {
            return category
        } else {
            // Lazy lookup from current campaign
            if let issue = store.state.issues.first(where: { String($0.id) == log.issueId }) {
                return CategoryHelper.primaryCategoryKey(from: issue).rawValue
            } else {
                return "none"  // Default for deleted campaigns
            }
        }
    }

    var weeklyStreak: Int {
        calculateWeeklyStreak()
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
                    AnimalsHelpedCard(count: totalActions)
                        .padding(.horizontal)

                    // Weekly Streak
                    WeeklyStreakSection(streak: weeklyStreak, hasActionThisWeek: hasActionThisWeek())
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
        let calendar = Calendar.current
        let now = Date()
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)!

        return store.state.issueCompletion.values.flatMap { $0 }.contains { action in
            thisWeek.contains(action.date)
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
}

struct Achievement {
    let title: String
    let subtitle: String
    let icon: String
    let category: AchievementCategory
    let isUnlocked: Bool
}

struct AnimalsHelpedCard: View {
    let count: Int

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

                        Text(count == 1 ? "Every action makes a difference" : "You've helped an entire sanctuary")
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
                WeeklyCalendarView(hasActionThisWeek: hasActionThisWeek)
            }
        }
    }
}

struct WeeklyCalendarView: View {
    let hasActionThisWeek: Bool

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    private let today = Calendar.current.component(.weekday, from: Date()) - 2 // Convert to 0-based Monday start

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                Text(weekdays[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(index == today && hasActionThisWeek ? Color.afaGreen : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(index == today && hasActionThisWeek ? .white : .primary)
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
        let phoneCallCount = store.state.issueCompletion.values.flatMap { $0 }.filter { $0.actionType == "call" }.count
        let emailActionCount = store.state.issueCompletion.values.flatMap { $0 }.filter { $0.actionType == "email" }.count
        let totalActionCount = store.state.issueCompletion.values.flatMap { $0 }.count
        let notificationsEnabled = notificationsAuthorized
        let remindersEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKey.reminderEnabled.rawValue)

        return [
            Achievement(
                title: "First Call",
                subtitle: "Completed your first phone call.",
                icon: "badge-first-call",
                category: .action,
                isUnlocked: phoneCallCount >= 1,
            ),
            Achievement(
                title: "Call Champion",
                subtitle: "Completed 10 phone calls.",
                icon: "badge-call-champion",
                category: .action,
                isUnlocked: phoneCallCount >= 10,
            ),
            Achievement(
                title: "Email Advocate",
                subtitle: "Completed your first email action.",
                icon: "badge-email-advocate",
                category: .action,
                isUnlocked: emailActionCount >= 1,
            ),
            Achievement(
                title: "Stay Informed",
                subtitle: "Signed up for notifications.",
                icon: "badge-notification",
                category: .action,
                isUnlocked: notificationsEnabled,
            ),
            Achievement(
                title: "Remind Me Later",
                subtitle: "Enabled reminders for actions.",
                icon: "badge-reminders",
                category: .action,
                isUnlocked: remindersEnabled,
            )
        ].sorted { $0.isUnlocked && !$1.isUnlocked }
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

    private func getCategory(for log: ContactLog) -> String {
        if let category = log.category {
            return category
        } else {
            // Lazy lookup from current campaign
            if let issue = store.state.issues.first(where: { String($0.id) == log.issueId }) {
                return CategoryHelper.primaryCategoryKey(from: issue).rawValue
            } else {
                return "none"  // Default for deleted campaigns
            }
        }
    }

    private func categoryActionCount(_ category: String) -> Int {
        return store.state.issueCompletion.values.flatMap { $0 }.filter { log in
            getCategory(for: log) == category
        }.count
    }

    private var achievements: [Achievement] {
        let farmedCount = categoryActionCount("farmed")
        let wildlifeCount = categoryActionCount("wildlife")
        let companionCount = categoryActionCount("companion")
        let entertainmentCount = categoryActionCount("entertainment")

        return [
            Achievement(
                title: "Farm Friend",
                subtitle: "5 actions for farmed animals.",
                icon: "badge-farmed",
                category: .animal,
                isUnlocked: farmedCount >= 5,
            ),
            Achievement(
                title: "Wildlife Warrior",
                subtitle: "5 actions for wildlife.",
                icon: "badge-wildlife",
                category: .animal,
                isUnlocked: wildlifeCount >= 5,
            ),
            Achievement(
                title: "Freedom Fighter",
                subtitle: "3 actions for entertainment.",
                icon: "badge-entertainment",
                category: .animal,
                isUnlocked: entertainmentCount >= 3,
            ),
            Achievement(
                title: "Rescue Ally",
                subtitle: "3 companion-animal actions.",
                icon: "badge-companion",
                category: .animal,
                isUnlocked: companionCount >= 3,
            )
        ].sorted { $0.isUnlocked && !$1.isUnlocked }
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

    private var totalAnimalsHelped: Int {
        store.state.issueCompletion.values.flatMap { $0 }.map { log in
            // If animalsHelped is not set, look it up from current campaign
            if let animalsHelped = log.animalsHelped {
                return animalsHelped
            } else {
                // Lazy lookup from current campaign
                if let issue = store.state.issues.first(where: { String($0.id) == log.issueId }) {
                    return issue.animalsHelpedPerAction
                } else {
                    return 1  // Default for deleted campaigns
                }
            }
        }.reduce(0, +)
    }

    private var achievements: [Achievement] {
        let totalActionCount = store.state.issueCompletion.values.flatMap { $0 }.count
        let weeklyStreak = store.state.weeklyStreak

        return [
            Achievement(
                title: "Goal Crusher",
                subtitle: "Completed 10 total actions.",
                icon: "badge-goal-crusher",
                category: .milestone,
                isUnlocked: totalActionCount >= 10,
            ),
            Achievement(
                title: "Century Advocate",
                subtitle: "Helped 100 animals.",
                icon: "badge-century-advocate",
                category: .milestone,
                isUnlocked: totalAnimalsHelped >= 100,
            ),
            Achievement(
                title: "Hot Streak",
                subtitle: "Maintained a 4-week streak.",
                icon: "badge-hot-streak",
                category: .milestone,
                isUnlocked: weeklyStreak >= 4,
            ),
            Achievement(
                title: "Peace for All Beings",
                subtitle: "Lifetime milestone — 500 animals helped.",
                icon: "badge-peace",
                category: .milestone,
                isUnlocked: totalAnimalsHelped >= 500,
            )
        ].sorted { $0.isUnlocked && !$1.isUnlocked }
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

    var compactSubtitle: String {
        // Convert long subtitles to compact versions
        let subtitle = achievement.subtitle

        if subtitle.contains("Completed your first phone call") {
            return "First phone call"
        } else if subtitle.contains("Completed 10 phone calls") {
            return "10 phone calls"
        } else if subtitle.contains("Completed your first email action") {
            return "First email action"
        } else if subtitle.contains("Signed up for notifications") {
            return "Signed up for notifications"
        } else if subtitle.contains("Enabled reminders for actions") {
            return "Enabled reminders"
        } else if subtitle.contains("5 actions for farmed animals") {
            return "5 farm actions"
        } else if subtitle.contains("5 actions for wildlife") {
            return "5 wildlife actions"
        } else if subtitle.contains("3 companion-animal actions") {
            return "3 companion actions"
        } else if subtitle.contains("3 actions for entertainment") {
            return "3 entertainment actions"
        } else if subtitle.contains("Completed 10 total actions") {
            return "10 total actions"
        } else if subtitle.contains("Helped 100 animals") {
            return "100 animals helped"
        } else if subtitle.contains("Maintained a 4-week streak") {
            return "4-week streak"
        } else if subtitle.contains("500 animals helped") {
            return "500 animals helped"
        } else {
            return subtitle
        }
    }

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

                Text(compactSubtitle)
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