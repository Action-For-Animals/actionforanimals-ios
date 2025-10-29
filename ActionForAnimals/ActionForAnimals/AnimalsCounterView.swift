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

    var body: some View {
        Button(action: {
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
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

#Preview {
    AnimalsCounterView()
}