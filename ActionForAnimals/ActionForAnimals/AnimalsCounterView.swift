//
//  AnimalsCounterView.swift
//  ActionForAnimals
//
//  Created by Claude on 10/28/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import SwiftUI

struct AnimalsCounterView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var impactManager: ImpactManager
    @State private var showDiscoveryHint = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseTimer: Timer?

    var body: some View {
        Button(action: {
            // Mark as seen when tapped
            if showDiscoveryHint {
                stopDiscoveryHint()
            }
            store.dispatch(action: .ShowYourImpact)
        }) {
            HStack(spacing: 6) {
                Text("\(store.totalAnimalsHelped)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.afaGreen)
                    .cornerRadius(12)
                    .scaleEffect(impactManager.showIncrementAnimation ? 1.2 : 1.0)
                    .opacity(impactManager.showIncrementAnimation ? 0.8 : 1.0)
                    .animation(.spring(duration: 0.6), value: impactManager.showIncrementAnimation)

                Image(.afaStars)
                    .accessibilityLabel("Your Impact")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(16)
            // Discovery hint glow effect
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.afaGreen, lineWidth: 2)
                    .opacity(showDiscoveryHint ? 0.8 : 0)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 0.6), value: pulseScale)
            )
            .shadow(
                color: showDiscoveryHint ? Color.afaGreen.opacity(0.5) : Color.clear,
                radius: showDiscoveryHint ? 8 : 0
            )
            .animation(.easeInOut(duration: 0.3), value: showDiscoveryHint)
        }
        .onAppear {
            checkForDiscoveryHint()
        }
    }

    private func checkForDiscoveryHint() {
        let hasSeenCounter = UserDefaults.standard.bool(forKey: "hasSeenImpactCounter")

        if !hasSeenCounter {
            // Show hint after a short delay to not overwhelm on first launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                startDiscoveryHint()

                // Auto-hide after 30 seconds if not tapped
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    if showDiscoveryHint {
                        stopDiscoveryHint()
                    }
                }
            }
        }
    }

    private func startDiscoveryHint() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showDiscoveryHint = true
        }

        // Start pulsing animation
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                pulseScale = pulseScale == 1.0 ? 1.1 : 1.0
            }
        }
    }

    private func stopDiscoveryHint() {
        UserDefaults.standard.set(true, forKey: "hasSeenImpactCounter")

        // Stop the pulsing timer
        pulseTimer?.invalidate()
        pulseTimer = nil

        // Reset scale and hide hint
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
            showDiscoveryHint = false
        }
    }
}

#Preview {
    AnimalsCounterView()
}