//
//  WelcomeStep1.swift
//  ActionForAnimals
//
//  Created by Claude on 2025-09-09.
//

import SwiftUI

struct WelcomeStep1: View {
    @EnvironmentObject var store: Store
    
    @State private var selectedCategories: Set<CategoryFilter> = [.all]
    
    let onContinue: (Set<CategoryFilter>) -> Void
    
    enum CategoryFilter: String, CaseIterable {
        case all = "all"
        case farmed = "farmed" 
        case wildlife = "wildlife"
        case companion = "companion"
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .farmed: return "Farmed" 
            case .wildlife: return "Wildlife"
            case .companion: return "Companion"
            }
        }
        
        
        var iconName: String {
            switch self {
            case .all: return "heart.fill"
            case .farmed: return "category-farmed"
            case .wildlife: return "category-wildlife"
            case .companion: return "category-companion"
            }
        }
    }
    
    private func toggleCategory(_ category: CategoryFilter) {
        if category == .all {
            // If "All" is selected, clear other selections and select only "All"
            selectedCategories = [.all]
        } else {
            // If any specific category is selected, remove "All" if it was selected
            selectedCategories.remove(.all)
            
            // Toggle the specific category
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
            
            // If no specific categories are selected, default back to "All"
            if selectedCategories.isEmpty {
                selectedCategories = [.all]
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo section
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
                    
                    Text("Turn your care for animals into meaningful action.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            Spacer()
            Spacer()
            
            // Category selection section
            VStack(spacing: 20) {
                Text("Choose your cause(s)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                // Category options in a grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 8) {
                    ForEach(CategoryFilter.allCases, id: \.rawValue) { category in
                        CategorySelectionCard(
                            category: category,
                            isSelected: selectedCategories.contains(category),
                            onTap: { toggleCategory(category) }
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                // Continue button
                Button(action: {
                    onContinue(selectedCategories)
                }) {
                    HStack {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear() {
            if store.state.globalCallCount == 0 {
                store.dispatch(action: .FetchStats(nil))
            }
        }
    }
}

struct CategorySelectionCard: View {
    let category: WelcomeStep1.CategoryFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Icon container - bigger icons, minimal background
                Group {
                    if category.iconName.hasPrefix("category-") {
                        Image(category.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: category.iconName)
                            .font(.system(size: 32, weight: .medium))
                    }
                }
                .foregroundColor(isSelected ? .white : (category == .all ? .red : .afaDarkBlue))
                
                // Title only
                Text(category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                // Selection indicator - tiny
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.secondary.opacity(0.6))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.afaDarkBlue : Color.afaLightBG)
                    .shadow(color: isSelected ? Color.afaDarkBlue.opacity(0.3) : Color.black.opacity(0.05), 
                           radius: isSelected ? 4 : 2, 
                           x: 0, 
                           y: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    WelcomeStep1(onContinue: { _ in })
        .environmentObject(Store(state: AppState()))
}