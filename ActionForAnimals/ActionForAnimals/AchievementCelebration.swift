//
//  AchievementCelebration.swift
//  ActionForAnimals
//
//  Created by Claude on 10/28/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import SwiftUI
import AudioToolbox


// MARK: - Main Achievement Celebration
struct AchievementCelebration: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var badgeScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }


            // Achievement content
            VStack(spacing: 20) {
                // Achievement badge with glow effect
                ZStack {
                    // Glow layers (multiple for stronger effect)
                    Group {
                        if achievement.icon.hasPrefix("badge-") {
                            Image(achievement.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        } else {
                            Text(achievement.icon)
                                .font(.system(size: 120))
                        }
                    }
                    .blur(radius: 20)
                    .opacity(glowOpacity * 0.6)
                    .scaleEffect(pulseScale * 1.2)

                    Group {
                        if achievement.icon.hasPrefix("badge-") {
                            Image(achievement.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                        } else {
                            Text(achievement.icon)
                                .font(.system(size: 120))
                        }
                    }
                    .blur(radius: 10)
                    .opacity(glowOpacity * 0.4)
                    .scaleEffect(pulseScale * 1.1)

                    // Main badge
                    if achievement.icon.hasPrefix("badge-") {
                        Image(achievement.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                    } else {
                        Text(achievement.icon)
                            .font(.system(size: 120))
                    }
                }
                .scaleEffect(badgeScale)

                // Achievement text
                VStack(spacing: 12) {
                    Text("🎉 Achievement Unlocked!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Text(achievement.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)

                    Text(achievement.subtitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .opacity(textOpacity)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startCelebrationAnimation()
            playAchievementSound()

            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismissCelebration()
            }
        }
    }

    private func startCelebrationAnimation() {
        // Background fade in
        withAnimation(.easeIn(duration: 0.3)) {
            backgroundOpacity = 1.0
        }

        // Badge scale in with bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
            badgeScale = 1.0
        }

        // Glow effect fade in
        withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
            glowOpacity = 1.0
        }

        // Start pulsing animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.6)) {
            pulseScale = 1.1
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            textOpacity = 1.0
        }
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0
            textOpacity = 0
            badgeScale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }

    private func playAchievementSound() {
        // Play success sound
        AudioServicesPlaySystemSound(1009)

        // Add haptic feedback for modern devices
        if #available(iOS 10.0, *) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()

            // Delay haptic slightly to sync with badge animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                impactFeedback.impactOccurred()
            }
        }
    }
}

#Preview {
    AchievementCelebration(
        achievement: Achievement(
            title: "Wildlife Warrior",
            subtitle: "5 actions for wildlife.",
            compactSubtitle: "5 wildlife actions",
            icon: "badge-wildlife",
            category: .animal,
            isUnlocked: true
        ),
        onDismiss: {}
    )
}