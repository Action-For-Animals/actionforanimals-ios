//
//  Dashboard.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 6/28/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct Dashboard: View {
    @EnvironmentObject var store: Store

    @State var selectedIssueUrl: URL?
    @Binding var selectedIssue: AnimalPolicy?

    @State var searchText = ""
    @State var selectedCategories: Set<CategoryKey> = [] // empty means "All"

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func usingRegularFonts() -> Bool {
        dynamicTypeSize < DynamicTypeSize.accessibility3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MainHeader()
                .padding(.horizontal, 10)
                
            if usingRegularFonts() {
                Text(R.string.localizable.takeActionForAnimals)
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 16)
            }
            
            SearchBar(searchText: $searchText)
            
            CategoryFilterBar(
                selectedCategories: $selectedCategories,
                availableCategories: CategoryHelper.availableCategories(from: store.state.issues)
            )

            IssuesList(
                store: store,
                selectedIssue: $selectedIssue,
                searchText: $searchText,
                selectedCategories: $selectedCategories
            )
        }
        .navigationBarHidden(true)
        .onAppear() {
            AnalyticsManager.shared.trackPageview(path: "/")
            print("📱 [Dashboard] onAppear() triggered")

            if let location = store.state.location {
                print("📍 [Dashboard] Location exists: \(location.locationDisplay)")
                if store.state.needsContactsRefresh {
                    if let contactsFetchTime = UserDefaults.standard.object(forKey: "contactsFetchTime") as? Date {
                        let ageSeconds = Date().timeIntervalSince(contactsFetchTime)
                        if ageSeconds < 3600 { // Less than 1 hour
                            let ageMinutes = ageSeconds / 60
                            print("🔄 [Dashboard] Fetching fresh contacts - cache expired (\(String(format: "%.1f", ageMinutes)) minutes old)")
                        } else if ageSeconds < 86400 { // Less than 1 day
                            let ageHours = ageSeconds / 3600
                            print("🔄 [Dashboard] Fetching fresh contacts - cache expired (\(String(format: "%.1f", ageHours)) hours old)")
                        } else {
                            let ageDays = ageSeconds / (24 * 60 * 60)
                            print("🔄 [Dashboard] Fetching fresh contacts - cache expired (\(String(format: "%.1f", ageDays)) days old)")
                        }
                    } else {
                        print("🔄 [Dashboard] Fetching fresh contacts - no previous fetch time")
                    }
                    store.dispatch(action: .FetchContacts(location))
                } else {
                    if let contactsFetchTime = UserDefaults.standard.object(forKey: "contactsFetchTime") as? Date {
                        let ageSeconds = Date().timeIntervalSince(contactsFetchTime)
                        if ageSeconds < 3600 { // Less than 1 hour
                            let ageMinutes = ageSeconds / 60
                            print("✅ [Dashboard] Using cached contacts - still fresh (\(String(format: "%.1f", ageMinutes)) minutes old)")
                        } else if ageSeconds < 86400 { // Less than 1 day
                            let ageHours = ageSeconds / 3600
                            print("✅ [Dashboard] Using cached contacts - still fresh (\(String(format: "%.1f", ageHours)) hours old)")
                        } else {
                            let ageDays = ageSeconds / (24 * 60 * 60)
                            print("✅ [Dashboard] Using cached contacts - still fresh (\(String(format: "%.1f", ageDays)) days old)")
                        }
                    } else {
                        print("✅ [Dashboard] Using cached contacts - no timestamp available")
                    }
                }
            } else {
                print("❌ [Dashboard] No location set")
            }

            // Initialize category filter from user preferences
            initializeCategoryFromPreferences()
        }
        .onOpenURL(perform: { url in
            if store.state.issues.isEmpty {
                selectedIssueUrl = url
            } else {
                selectedIssue = store.state.issues.first(where: { $0.slug == url.lastPathComponent })
            }
        })

        .onChange(of: store.state.issues) { issues in
            if let selectedIssueUrl {
                selectedIssue = issues.first(where: { $0.slug == selectedIssueUrl.lastPathComponent })
                self.selectedIssueUrl = nil
            }
        }
        .onChange(of: store.state.selectedCategoryFilter) { _ in
            initializeCategoryFromPreferences()
        }
    }
    
    private func initializeCategoryFromPreferences() {
        let userPreferences = store.state.selectedCategoryFilters
        
        // If user selected "all", show all (empty set)
        if userPreferences.contains("all") {
            selectedCategories = []
        } else {
            // Convert WelcomeStep1 category strings to CategoryKey set
            var categories: Set<CategoryKey> = []
            for preference in userPreferences {
                switch preference {
                case "farmed":
                    categories.insert(.farmed)
                case "wildlife":
                    categories.insert(.wildlife)
                case "companion":
                    categories.insert(.companion)
                default:
                    break
                }
            }
            selectedCategories = categories
        }
    }
}

struct CategoryFilterBar: View {
    @Binding var selectedCategories: Set<CategoryKey>
    let availableCategories: [CategoryKey]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                CategoryFilterChip(
                    title: "All",
                    isSelected: selectedCategories.isEmpty
                ) {
                    // Toggle all - if currently empty (all selected), do nothing
                    // If some are selected, clear all to show all
                    selectedCategories = []
                }
                
                // Dynamic category filters based on available categories
                ForEach(availableCategories, id: \.self) { categoryKey in
                    CategoryFilterChip(
                        title: categoryKey.displayName,
                        isSelected: selectedCategories.contains(categoryKey)
                    ) {
                        // Toggle this specific category
                        if selectedCategories.contains(categoryKey) {
                            selectedCategories.remove(categoryKey)
                        } else {
                            selectedCategories.insert(categoryKey)
                        }
                    }
                }
                
                // Invisible spacer to ensure last chip isn't cut off
                Spacer(minLength: 16)
            }
            .padding(.leading, 16)
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Dashboard_Previews: PreviewProvider {
    static let previewState = {
        var state = AppState()
        state.issues = [
            AnimalPolicy.basicPreviewIssue,
            AnimalPolicy.multilinePreviewIssue
        ]
        state.contacts = [
            Contact.housePreviewContact,
            Contact.senatePreviewContact1,
            Contact.senatePreviewContact2
        ]
        return state
    }()

    static let store = Store(state: previewState, middlewares: [appMiddleware()])

    static var previews: some View {
        NavigationStack {
            Dashboard(selectedIssue: .constant(.none)).environmentObject(store)
        }
    }
}

struct MenuView: View {
    @State var showSettingsSheet = false
    var showingWelcomeScreen: Bool

    var body: some View {
        Button(action: {
            showSettingsSheet = true
        }) {
            Image(systemName: "gear")
                .renderingMode(.template)
                .font(.title)
                .accessibilityLabel(Text(R.string.localizable.menuName))
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheet()
        }
    }
}

struct IssuesList: View {
    @ObservedObject var store: Store
    @Binding var selectedIssue: AnimalPolicy?
    @Binding var searchText: String
    @Binding var selectedCategories: Set<CategoryKey>
    
    var isSearching: Bool {
        searchText.count >= 3
    }
    
    var selectedCategoriesDisplayName: String {
        if selectedCategories.isEmpty {
            return "All"
        } else if selectedCategories.count == 1 {
            return selectedCategories.first?.displayName ?? "Selected"
        } else {
            let names = selectedCategories.map { $0.displayName }
            return names.joined(separator: " & ")
        }
    }

    // Filter issues by both search and category using CategoryHelper
    var filteredIssues: [AnimalPolicy] {
        var issues = store.state.issues
        
        // Apply category filter using CategoryHelper
        if !selectedCategories.isEmpty {
            issues = issues.filter { issue in
                let primaryCategory = CategoryHelper.primaryCategoryKey(from: issue)
                return selectedCategories.contains(primaryCategory)
            }
        }
        
        // Apply search filter
        if isSearching {
            issues = issues.filter { issue in
                issue.name.localizedCaseInsensitiveContains(searchText) ||
                issue.reason.localizedCaseInsensitiveContains(searchText) ||
                (issue.script?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                issue.slug.localizedCaseInsensitiveContains(searchText) ||
                issue.categories.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
            
            // Sort so that name matches come first
            issues = issues.sorted { a, b in
                let am = a.name.localizedCaseInsensitiveContains(searchText)
                let bm = b.name.localizedCaseInsensitiveContains(searchText)
                return am && !bm
            }
        }
        
        return issues
    }

    var body: some View {
        if isSearching && filteredIssues.isEmpty {
            VStack {
                Spacer()
                Text(R.string.localizable.searchNoResultsTitle())
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text(R.string.localizable.searchNoResultsMessage())
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !isSearching && filteredIssues.isEmpty && !selectedCategories.isEmpty {
            VStack {
                Spacer()
                Text("No \(selectedCategoriesDisplayName) Campaigns")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Try selecting different categories")
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Flat list showing filtered results
            List(filteredIssues, selection: $selectedIssue) { issue in
                NavigationLink(value: issue) {
                    AnimalPolicyListItem(issue: issue, contacts: store.state.contacts)
                }
                .listRowSeparatorTint(.afaDarkGray)
            }
            .tint(Color.afaLightBG)
            .listStyle(.plain)
        }
    }
}
