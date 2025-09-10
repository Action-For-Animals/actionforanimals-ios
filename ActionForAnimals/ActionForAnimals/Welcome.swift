//
//  Welcome.swift
//  ActionForAnimals
//
//  Created by Christopher Selin on 10/21/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    @State private var currentStep = 1
    @State private var selectedCategories: Set<WelcomeStep1.CategoryFilter> = [.all]

    var onContinue: (() -> Void)?

    var body: some View {
        Group {
            if currentStep == 1 {
                WelcomeStep1(onContinue: { categories in
                    selectedCategories = categories
                    // Save category preferences as comma-separated string
                    let categoryString = categories.map { $0.rawValue }.sorted().joined(separator: ",")
                    store.dispatch(action: .SetCategoryFilter(categoryString))
                    currentStep = 2
                })
            } else {
                WelcomeStep2(selectedCategories: selectedCategories, onComplete: {
                    onContinue?()
                    dismiss()
                })
            }
        }
    }
}

struct Welcome_Previews: PreviewProvider {
    static let previewState = {
        var state = AppState()
        state.globalCallCount = 12345
        return state
    }()

    static let previewStore = Store(state: previewState, middlewares: [appMiddleware()])

    static var previews: some View {
        Welcome().environmentObject(previewStore)
    }
}
