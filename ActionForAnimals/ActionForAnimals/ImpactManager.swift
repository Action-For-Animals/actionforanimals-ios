//
//  ImpactManager.swift
//  ActionForAnimals
//
//  Created by Claude on 10/28/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import SwiftUI
import Combine
import AudioToolbox

class ImpactManager: ObservableObject {
    static var shared: ImpactManager?

    @Published var showAchievementAlert: Achievement? = nil
    @Published var showAchievementCelebration: Achievement? = nil
    @Published var showIncrementAnimation: Bool = false
    @Published var recentlyUnlockedAchievements: [Achievement] = []
    @Published var hasNewAchievements: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var store: Store?

    func configure(with store: Store) {
        self.store = store
        ImpactManager.shared = self
    }

    func handleNewAction(_ log: ContactLog, from issue: AnimalPolicy, store: Store) {
        let animalsFromThisAction = log.animalsHelped ?? issue.animalsHelpedPerAction

        // Only animate if we're actually adding animals (not skipping)
        guard animalsFromThisAction > 0 else { return }

        // 1. Animate counter increment
        withAnimation(.spring(duration: 0.6)) {
            showIncrementAnimation = true
        }

        // Play subtle counter sound
        AudioServicesPlaySystemSound(1105)

        // Add light haptic feedback for counter
        if #available(iOS 10.0, *) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }

        // 2. Check for newly unlocked achievements using shared logic
        let newAchievements = store.checkNewlyUnlockedAchievements(after: log)
        if let newAchievement = newAchievements.first {
            showAchievementCelebration = newAchievement
            recentlyUnlockedAchievements.append(newAchievement)
            hasNewAchievements = true
        }

        // 3. Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeOut) {
                self.showIncrementAnimation = false
            }
        }
    }

    func markAchievementsAsSeen() {
        hasNewAchievements = false
    }

    func dismissAchievementAlert() {
        showAchievementAlert = nil
    }

    func dismissAchievementCelebration() {
        showAchievementCelebration = nil
    }

    func resetAnimation() {
        showIncrementAnimation = false
    }
}