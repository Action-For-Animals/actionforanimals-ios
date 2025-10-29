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
                            store.dispatch(action: .FetchIssues)
                        }
                    }
                }
        }
    }
}

