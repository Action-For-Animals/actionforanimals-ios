//
//  MainHeader.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 3/16/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import SwiftUI

struct MainHeader: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var impactManager: ImpactManager

    @State var showLocationSheet = false

    var body: some View {
        HStack {
            MenuView(showingWelcomeScreen: store.state.showWelcomeScreen)

            Spacer()

            LocationHeader(location: store.state.location,
                           isSplit: store.state.isSplitDistrict,
                           lowAccuracyMessage: store.state.lowAccuracyMessage,
                           fetchingContacts: store.state.fetchingContacts)
                .padding(.bottom, 10)
                .onTapGesture {
                    showLocationSheet.toggle()
                }
                .sheet(isPresented: $showLocationSheet) {
                    LocationSheet()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .padding(.top, 40)
                    Spacer()
                }

            AnimalsCounterView()
        }
        .alert("Achievement Unlocked! 🎉", isPresented: .constant(impactManager.showAchievementAlert != nil)) {
            Button("View Your Impact") {
                impactManager.dismissAchievementAlert()
                store.dispatch(action: .ShowYourImpact)
            }
            Button("OK") {
                impactManager.dismissAchievementAlert()
            }
        } message: {
            if let achievement = impactManager.showAchievementAlert {
                Text("You earned: \(achievement.title)!\n\(achievement.subtitle)")
            }
        }
    }
}

#Preview {
    MainHeader()
}
