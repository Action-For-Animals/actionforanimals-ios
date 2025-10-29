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

    func getCategory(for log: ContactLog) -> String {
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

    func categoryActionCount(_ category: String) -> Int {
        return state.issueCompletion.values.flatMap { $0 }.filter { log in
            getCategory(for: log) == category
        }.count
    }

    func checkNewlyUnlockedAchievements(after newLog: ContactLog) -> [Achievement] {
        return AchievementRegistry.allAchievements
            .filter { $0.checkNewlyUnlocked(self, newLog) }
            .map { AchievementRegistry.createAchievement(from: $0, store: self) }
    }
}