//
//  ImpactCalculator.swift
//  ActionForAnimals
//
//  Created by Claude on 10/28/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import Foundation

// MARK: - Shared Impact & Achievement Logic
extension Store {

    // MARK: - Core Metrics

    var totalAnimalsHelped: Int {
        state.issueCompletion.values.flatMap { $0 }.map { log in
            if let animalsHelped = log.animalsHelped {
                return animalsHelped
            } else {
                if let issue = state.issues.first(where: { String($0.id) == log.issueId }) {
                    return issue.animalsHelpedPerAction
                } else {
                    return 1
                }
            }
        }.reduce(0, +)
    }

    var phoneCallCount: Int {
        state.issueCompletion.values.flatMap { $0 }.filter { $0.actionType == "call" }.count
    }

    var emailActionCount: Int {
        state.issueCompletion.values.flatMap { $0 }.filter { $0.actionType == "email" }.count
    }

    var totalActionCount: Int {
        state.issueCompletion.values.flatMap { $0 }.count
    }

    var notificationsEnabled: Bool {
        UserDefaults.standard.object(forKey: UserDefaultsKey.lastAskedForNotificationPermission.rawValue) != nil
    }

    var remindersEnabled: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKey.reminderEnabled.rawValue)
    }

    // MARK: - Achievement Checking

    private func getCategory(for log: ContactLog) -> String {
        if let category = log.category {
            return category
        } else {
            // Lazy lookup from current campaign
            if let issue = state.issues.first(where: { String($0.id) == log.issueId }) {
                return CategoryHelper.primaryCategoryKey(from: issue).rawValue
            } else {
                return "none"  // Default for deleted campaigns
            }
        }
    }

    private func categoryActionCount(_ category: String) -> Int {
        return state.issueCompletion.values.flatMap { $0 }.filter { log in
            getCategory(for: log) == category
        }.count
    }

    func checkNewlyUnlockedAchievements(after newLog: ContactLog) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        // Check action achievements
        if phoneCallCount == 1 {
            newlyUnlocked.append(Achievement(
                title: "First Call",
                subtitle: "Completed your first phone call.",
                icon: "badge-first-call",
                category: .action,
                isUnlocked: true,
            ))
        }

        if phoneCallCount == 10 {
            newlyUnlocked.append(Achievement(
                title: "Call Champion",
                subtitle: "Completed 10 phone calls.",
                icon: "badge-call-champion",
                category: .action,
                isUnlocked: true,
            ))
        }

        if emailActionCount == 1 {
            newlyUnlocked.append(Achievement(
                title: "Email Advocate",
                subtitle: "Completed your first email action.",
                icon: "badge-email-advocate",
                category: .action,
                isUnlocked: true,
            ))
        }

        // Removed "Action Starter" achievement - too complex to track campaign completion reliably

        // Check milestone achievements
        if totalActionCount == 10 {
            newlyUnlocked.append(Achievement(
                title: "Goal Crusher",
                subtitle: "Completed 10 total actions.",
                icon: "badge-goal-crusher",
                category: .milestone,
                isUnlocked: true,
            ))
        }

        let animalsFromThisAction = newLog.animalsHelped ?? 1
        if totalAnimalsHelped >= 100 && totalAnimalsHelped - animalsFromThisAction < 100 {
            newlyUnlocked.append(Achievement(
                title: "Century Advocate",
                subtitle: "Helped 100 animals.",
                icon: "badge-century-advocate",
                category: .milestone,
                isUnlocked: true,
            ))
        }

        if totalAnimalsHelped >= 500 && totalAnimalsHelped - animalsFromThisAction < 500 {
            newlyUnlocked.append(Achievement(
                title: "Peace for All Beings",
                subtitle: "Lifetime milestone — 500 animals helped.",
                icon: "badge-peace",
                category: .milestone,
                isUnlocked: true,
            ))
        }

        // Check category-based achievements
        let newLogCategory = getCategory(for: newLog)
        let categoryCount = categoryActionCount(newLogCategory)

        // Wildlife achievement
        if newLogCategory == "wildlife" && categoryCount == 5 {
            newlyUnlocked.append(Achievement(
                title: "Wildlife Warrior",
                subtitle: "5 actions for wildlife.",
                icon: "badge-wildlife",
                category: .animal,
                isUnlocked: true,
            ))
        }

        // Farmed animals achievement
        if newLogCategory == "farmed" && categoryCount == 5 {
            newlyUnlocked.append(Achievement(
                title: "Farm Friend",
                subtitle: "5 actions for farmed animals.",
                icon: "badge-farmed",
                category: .animal,
                isUnlocked: true,
            ))
        }

        // Companion animals achievement
        if newLogCategory == "companion" && categoryCount == 3 {
            newlyUnlocked.append(Achievement(
                title: "Rescue Ally",
                subtitle: "3 companion-animal actions.",
                icon: "badge-companion",
                category: .animal,
                isUnlocked: true,
            ))
        }

        // Entertainment achievement
        if newLogCategory == "entertainment" && categoryCount == 3 {
            newlyUnlocked.append(Achievement(
                title: "Freedom Fighter",
                subtitle: "3 actions for entertainment.",
                icon: "badge-entertainment",
                category: .animal,
                isUnlocked: true,
            ))
        }

        // Note: Notifications and reminders achievements are checked separately
        // when those settings are actually enabled, not during action completion

        return newlyUnlocked
    }
}