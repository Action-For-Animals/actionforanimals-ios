//
//  WelcomeStep2.swift
//  ActionForAnimals
//
//  Created by Claude on 2025-09-09.
//

import SwiftUI

struct WelcomeStep2: View {
    @AppStorage(UserDefaultsKey.hasShownWelcomeScreen.rawValue) var hasShownWelcomeScreen = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    
    @State private var showLocationSheet = false
    
    let selectedCategories: Set<WelcomeStep1.CategoryFilter>
    let onComplete: (() -> Void)?
    
    private var categoryDisplayText: String {
        if selectedCategories.contains(.all) || selectedCategories.count > 2 {
            return "all"
        } else if selectedCategories.count == 2 {
            let names = selectedCategories.map { $0.displayName.lowercased() }
            return names.joined(separator: " and ")
        } else if let singleCategory = selectedCategories.first {
            return singleCategory.displayName.lowercased()
        } else {
            return "all"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo section (consistent with Step 1)
            VStack(spacing: 24) {
                Image(decorative: R.image.afaLogotype)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250)
                
                VStack(spacing: 16) {
                    Text("Take Action for Animals")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Great! You're interested in \(categoryDisplayText) campaigns.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            // Progress indicator
            HStack {
                Circle()
                    .fill(Color.afaDarkBlue)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(Color.afaDarkBlue)
                    .frame(height: 2)
                
                Circle()
                    .fill(Color.afaDarkBlue)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 100)
            .padding(.bottom, 32)
            
            Spacer()
            
            // Location setup section
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Set Your Location to Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We need your location to find your representatives and show relevant campaigns.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Button(action: {
                    showLocationSheet = true
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .font(.title3)
                        Text("Set Location")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .onAppear() {
            hasShownWelcomeScreen = true
        }
        .sheet(isPresented: $showLocationSheet) {
            LocationSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: store.state.location) { location in
            if location != nil {
                // Location was set, complete onboarding
                onComplete?()
                dismiss()
            }
        }
    }
}

#Preview {
    WelcomeStep2(selectedCategories: [.farmed, .wildlife], onComplete: nil)
        .environmentObject(Store(state: AppState()))
}