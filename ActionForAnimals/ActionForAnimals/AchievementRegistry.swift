//
//  AchievementRegistry.swift
//  ActionForAnimals
//
//  Created by Claude on 10/28/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import Foundation
import OneSignal

struct AchievementThresholds {
    static let firstCall = 1
    static let callChampion = 10
    static let firstEmail = 1
    static let goalCrusher = 10
    static let centuryAdvocate = 100
    static let peaceMilestone = 500
    static let animalCategoryMajor = 5
    static let animalCategoryMinor = 3
}

struct AchievementDefinition {
    let id: String
    let title: String
    let subtitle: String
    let compactSubtitle: String
    let icon: String
    let category: AchievementCategory
    let checkUnlocked: (Store) -> Bool
    let checkNewlyUnlocked: (Store, ContactLog) -> Bool
}

class AchievementRegistry {
    static let allAchievements: [AchievementDefinition] = [
        // Action Achievements
        AchievementDefinition(
            id: "first_call",
            title: "First Call",
            subtitle: "Completed your first phone call.",
            compactSubtitle: "First phone call",
            icon: "badge-first-call",
            category: .action,
            checkUnlocked: { store in store.phoneCallCount >= AchievementThresholds.firstCall },
            checkNewlyUnlocked: { store, log in
                log.actionType == "call" && store.phoneCallCount == AchievementThresholds.firstCall
            }
        ),
        AchievementDefinition(
            id: "call_champion",
            title: "Call Champion",
            subtitle: "Completed 10 phone calls.",
            compactSubtitle: "10 phone calls",
            icon: "badge-call-champion",
            category: .action,
            checkUnlocked: { store in store.phoneCallCount >= AchievementThresholds.callChampion },
            checkNewlyUnlocked: { store, log in
                log.actionType == "call" && store.phoneCallCount == AchievementThresholds.callChampion
            }
        ),
        AchievementDefinition(
            id: "email_advocate",
            title: "Email Advocate",
            subtitle: "Completed your first email action.",
            compactSubtitle: "First email action",
            icon: "badge-email-advocate",
            category: .action,
            checkUnlocked: { store in store.emailActionCount >= AchievementThresholds.firstEmail },
            checkNewlyUnlocked: { store, log in
                log.actionType == "email" && store.emailActionCount == AchievementThresholds.firstEmail
            }
        ),

        // Animal Achievements (in order: Farm → Wildlife → Entertainment → Companion)
        AchievementDefinition(
            id: "farm_friend",
            title: "Farm Friend",
            subtitle: "5 actions for farmed animals.",
            compactSubtitle: "5 farmed animal actions",
            icon: "badge-farmed",
            category: .animal,
            checkUnlocked: { store in store.categoryActionCount("farmed") >= AchievementThresholds.animalCategoryMajor },
            checkNewlyUnlocked: { store, log in
                store.getCategory(for: log) == "farmed" && store.categoryActionCount("farmed") == AchievementThresholds.animalCategoryMajor
            }
        ),
        AchievementDefinition(
            id: "wildlife_warrior",
            title: "Wildlife Warrior",
            subtitle: "5 actions for wildlife.",
            compactSubtitle: "5 wildlife actions",
            icon: "badge-wildlife",
            category: .animal,
            checkUnlocked: { store in store.categoryActionCount("wildlife") >= AchievementThresholds.animalCategoryMajor },
            checkNewlyUnlocked: { store, log in
                store.getCategory(for: log) == "wildlife" && store.categoryActionCount("wildlife") == AchievementThresholds.animalCategoryMajor
            }
        ),
        AchievementDefinition(
            id: "freedom_fighter",
            title: "Freedom Fighter",
            subtitle: "3 actions for entertainment.",
            compactSubtitle: "3 entertainment actions",
            icon: "badge-entertainment",
            category: .animal,
            checkUnlocked: { store in store.categoryActionCount("entertainment") >= AchievementThresholds.animalCategoryMinor },
            checkNewlyUnlocked: { store, log in
                store.getCategory(for: log) == "entertainment" && store.categoryActionCount("entertainment") == AchievementThresholds.animalCategoryMinor
            }
        ),
        AchievementDefinition(
            id: "rescue_ally",
            title: "Rescue Ally",
            subtitle: "3 companion-animal actions.",
            compactSubtitle: "3 companion actions",
            icon: "badge-companion",
            category: .animal,
            checkUnlocked: { store in store.categoryActionCount("companion") >= AchievementThresholds.animalCategoryMinor },
            checkNewlyUnlocked: { store, log in
                store.getCategory(for: log) == "companion" && store.categoryActionCount("companion") == AchievementThresholds.animalCategoryMinor
            }
        ),

        // Milestone Achievements
        AchievementDefinition(
            id: "goal_crusher",
            title: "Goal Crusher",
            subtitle: "Completed 10 total actions.",
            compactSubtitle: "10 total actions",
            icon: "badge-goal-crusher",
            category: .milestone,
            checkUnlocked: { store in store.totalActionCount >= AchievementThresholds.goalCrusher },
            checkNewlyUnlocked: { store, _ in store.totalActionCount == AchievementThresholds.goalCrusher }
        ),
        AchievementDefinition(
            id: "century_advocate",
            title: "Century Advocate",
            subtitle: "Helped 100 animals.",
            compactSubtitle: "100 animals helped",
            icon: "badge-century-advocate",
            category: .milestone,
            checkUnlocked: { store in store.totalAnimalsHelped >= AchievementThresholds.centuryAdvocate },
            checkNewlyUnlocked: { store, log in
                let animalsFromThisAction = log.animalsHelped ?? 1
                return store.totalAnimalsHelped >= AchievementThresholds.centuryAdvocate &&
                       store.totalAnimalsHelped - animalsFromThisAction < AchievementThresholds.centuryAdvocate
            }
        ),
        AchievementDefinition(
            id: "peace_for_all_beings",
            title: "Peace for All Beings",
            subtitle: "Lifetime milestone — 500 animals helped.",
            compactSubtitle: "500 animals helped",
            icon: "badge-peace",
            category: .milestone,
            checkUnlocked: { store in store.totalAnimalsHelped >= AchievementThresholds.peaceMilestone },
            checkNewlyUnlocked: { store, log in
                let animalsFromThisAction = log.animalsHelped ?? 1
                return store.totalAnimalsHelped >= AchievementThresholds.peaceMilestone &&
                       store.totalAnimalsHelped - animalsFromThisAction < AchievementThresholds.peaceMilestone
            }
        ),

        // Hot Streak Achievement (moved from milestone to avoid confusion)
        AchievementDefinition(
            id: "hot_streak",
            title: "Hot Streak",
            subtitle: "Maintained a 4-week streak.",
            compactSubtitle: "4-week streak",
            icon: "badge-hot-streak",
            category: .milestone,
            checkUnlocked: { store in store.state.weeklyStreak >= 4 },
            checkNewlyUnlocked: { store, _ in store.state.weeklyStreak == 4 }
        ),

        // Settings Achievements
        AchievementDefinition(
            id: "stay_informed",
            title: "Stay Informed",
            subtitle: "Signed up for notifications.",
            compactSubtitle: "Notifications enabled",
            icon: "badge-notification",
            category: .settings,
            checkUnlocked: { store in OneSignal.getDeviceState()?.hasNotificationPermission ?? false },
            checkNewlyUnlocked: { _, _ in false } // Not triggered by actions
        ),
        AchievementDefinition(
            id: "remind_me_later",
            title: "Remind Me Later",
            subtitle: "Enabled reminders for actions.",
            compactSubtitle: "Reminders enabled",
            icon: "badge-reminders",
            category: .settings,
            checkUnlocked: { store in store.remindersEnabled },
            checkNewlyUnlocked: { _, _ in false } // Not triggered by actions
        )
    ]

    static func createAchievement(from definition: AchievementDefinition, store: Store) -> Achievement {
        return Achievement(
            title: definition.title,
            subtitle: definition.subtitle,
            compactSubtitle: definition.compactSubtitle,
            icon: definition.icon,
            category: definition.category,
            isUnlocked: definition.checkUnlocked(store)
        )
    }

    static func achievementsByCategory(_ category: AchievementCategory) -> [AchievementDefinition] {
        return allAchievements.filter { $0.category == category }
    }
}