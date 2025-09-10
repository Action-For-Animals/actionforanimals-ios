//
//  OutcomesView.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 10/12/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct OutcomesView: View {
    let outcomes: [Outcome]
    let report: (Outcome) -> ()
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible())]) {
            ForEach(outcomes) { outcome in
                PrimaryButton(title: outcome.label)
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    report(outcome)
                }
            }
        }
    }
}

#Preview {
    OutcomesView(outcomes: [Outcome(label: "Left Voicemail", status: "vm"),Outcome(label: "No", status: "no"),Outcome(label: "Maybe", status: "maybe")], report: { _ in })
        .padding()
}
