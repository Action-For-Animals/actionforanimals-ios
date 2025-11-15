//
//  App.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 6/28/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

@main
struct ActionForAnimalsApp: App {
    @StateObject var store: Store = Store(state: AppState(), middlewares: [appMiddleware()])
    @StateObject var impactManager: ImpactManager = ImpactManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var scenePhase
            
    @AppStorage(UserDefaultsKey.hasShownWelcomeScreen.rawValue) var hasShownWelcomeScreen = false
    @AppStorage("lastCheckedMonth") var lastCheckedMonth = ""
    @State private var showMonthTransition = false
    @State private var monthTransitionData: MonthTransitionData? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                AnimalPolicySplitView()
                    .environmentObject(store)
                    .environmentObject(impactManager)
                    .sheet(isPresented: $store.state.showWelcomeScreen) {
                        Welcome().environmentObject(store)
                    }

                // Achievement celebration overlay
                if let achievement = impactManager.showAchievementCelebration {
                    AchievementCelebration(
                        achievement: achievement,
                        onDismiss: {
                            impactManager.dismissAchievementCelebration()
                        }
                    )
                    .zIndex(1000)
                }

            }
                .onAppear {
                    appDelegate.app = self
                    impactManager.configure(with: store)
                    if !hasShownWelcomeScreen {
                        store.dispatch(action: .ShowWelcomeScreen)
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        if store.state.needsIssueRefresh {
                            if let lastFetch = store.state.issueFetchTime {
                                let minutesAgo = Date().timeIntervalSince(lastFetch) / 60
                                print("🔄 [App] Fetching fresh issues - cache expired (\(String(format: "%.1f", minutesAgo)) minutes old)")
                            } else if !store.state.issues.isEmpty {
                                print("🔄 [App] Fetching fresh issues - using cached data, checking for updates")
                            } else {
                                print("🔄 [App] Fetching fresh issues - no previous data")
                            }
                            store.dispatch(action: .FetchIssues)
                        } else {
                            print("✅ [App] Using cached issues - still fresh")
                        }

                        // Refresh leaderboard cache only if user is in current month's league
                        if isUserInCurrentMonthLeague() {
                            print("🏆 [App] User is in league - refreshing leaderboard cache")
                            store.dispatch(action: .FetchCurrentLeaderboard)
                        } else {
                            print("🏆 [App] User not in current league - skipping leaderboard refresh")
                        }

                        // Check for month transition
                        checkMonthTransition()
                    }
                }
                .sheet(isPresented: $showMonthTransition) {
                    MonthTransitionView(data: monthTransitionData)
                        .environmentObject(store)
                }
        }
    }

    // MARK: - Month Transition Logic
    private func checkMonthTransition() {
        let currentMonth = getCurrentMonthKey()

        // If this is the first time checking or we've entered a new month
        if lastCheckedMonth.isEmpty {
            // First launch - just store current month without showing transition
            lastCheckedMonth = currentMonth
            return
        }

        if lastCheckedMonth != currentMonth {
            // We've entered a new month!
            print("Month transition detected: \(lastCheckedMonth) -> \(currentMonth)")

            // Only show celebration if user was in previous month's league
            let wasInPreviousMonth = UserDefaults.standard.string(forKey: UserDefaultsKey.lastLeagueMonth.rawValue) == lastCheckedMonth

            if wasInPreviousMonth {
                // Show transition screen immediately with loading state
                showMonthTransition = true
                let operation = GetMonthlyLeagueResultsOperation(monthKey: lastCheckedMonth)
                let queue = OperationQueue()

                operation.completionBlock = {
                    DispatchQueue.main.async {
                        if operation.success, let data = operation.monthTransitionData {
                            self.monthTransitionData = data
                        } else {
                            print("Failed to fetch month transition data")
                            // Keep the screen open but with no data (will show fallback)
                        }
                    }
                }

                queue.addOperation(operation)
            }

            // Reset monthly animals count
            store.dispatch(action: .IncrementMonthlyAnimals(-store.state.animalsHelpedThisMonth))

            // Clear cached leaderboard data from previous month
            store.state.cachedCurrentLeaderboard = []
            store.state.cachedCurrentMeta = nil
            print("🏆 [App] Cleared cached leaderboard data for new month")

            // Update stored month
            lastCheckedMonth = currentMonth
        }
    }

    private func getCurrentMonthKey() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()
        return String(format: "%04d-%02d",
                     calendar.component(.year, from: now),
                     calendar.component(.month, from: now))
    }

    private func isUserInCurrentMonthLeague() -> Bool {
        let currentMonthKey = getCurrentMonthKey()
        let lastLeagueMonth = UserDefaults.standard.string(forKey: UserDefaultsKey.lastLeagueMonth.rawValue)
        return lastLeagueMonth == currentMonthKey
    }

    private func fetchPreviousMonthWinners(monthKey: String, completion: @escaping ([String]) -> Void) {
        // For now, return empty array - we'll implement this when we add the backend endpoint
        completion([])
    }
}

