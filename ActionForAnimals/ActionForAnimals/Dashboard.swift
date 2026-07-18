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

            // All contacts loading is now handled by App.scenePhase
            print("📱 [Dashboard] onAppear - contacts handled by App lifecycle")

            // Initialize category filter from user preferences
            initializeCategoryFromPreferences()
        }
        .onOpenURL(perform: { url in
            store.state.selectedTab = "issues"
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

    @State private var showCompleted = false

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
        } else {
            // Campaigns that still need action come first; within that group, campaigns
            // with a deadline are ordered by proximity, everything else keeps the existing
            // backend/editorial order (Swift's sort is stable, so equal-priority pairs
            // don't get reshuffled). Fully completed, unchanged campaigns sink to the bottom.
            issues = issues.sorted { a, b in
                let aNeedsAction = store.state.needsAction(issue: a)
                let bNeedsAction = store.state.needsAction(issue: b)
                if aNeedsAction != bNeedsAction {
                    return aNeedsAction && !bNeedsAction
                }

                // A passed deadline shouldn't outrank a genuinely upcoming one, so treat
                // it the same as "no deadline" here.
                let aDays = (a.daysUntilDeadline ?? -1) >= 0 ? a.daysUntilDeadline : nil
                let bDays = (b.daysUntilDeadline ?? -1) >= 0 ? b.daysUntilDeadline : nil
                switch (aDays, bDays) {
                case let (da?, db?): return da < db
                case (.some, nil): return true
                case (nil, .some): return false
                case (nil, nil): return false
                }
            }
        }

        return issues
    }

    // Splits from the already-sorted filteredIssues, so relative ordering within each
    // group (deadline proximity, then backend order) carries over unchanged.
    var needsActionIssues: [AnimalPolicy] {
        filteredIssues.filter { store.state.needsAction(issue: $0) }
    }

    var completedIssues: [AnimalPolicy] {
        filteredIssues.filter { !store.state.needsAction(issue: $0) }
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
        } else if isSearching {
            // Flat list while actively searching, unchanged behavior
            List(filteredIssues, selection: $selectedIssue) { issue in
                NavigationLink(value: issue) {
                    AnimalPolicyListItem(issue: issue, contacts: store.state.contacts)
                }
                .listRowSeparatorTint(.afaDarkGray)
            }
            .tint(Color.afaLightBG)
            .listStyle(.plain)
        } else {
            // Split into a primary list and a separate "Completed" section, so fully
            // settled campaigns are visually set apart rather than just sorted lower
            // within one continuous list.
            List(selection: $selectedIssue) {
                ForEach(needsActionIssues) { issue in
                    NavigationLink(value: issue) {
                        AnimalPolicyListItem(issue: issue, contacts: store.state.contacts)
                    }
                    .listRowSeparatorTint(.afaDarkGray)
                }

                if !completedIssues.isEmpty {
                    CompletedSectionHeaderCard(
                        count: completedIssues.count,
                        isExpanded: $showCompleted
                    )
                    .plainListRow()

                    if showCompleted {
                        ForEach(completedIssues) { issue in
                            NavigationLink(value: issue) {
                                AnimalPolicyListItem(issue: issue, contacts: store.state.contacts, isCompletedRow: true)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemGray6).opacity(0.5))
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparatorTint(.afaDarkGray)
                        }
                    }

                    ImpactStatsCard(
                        campaignsCompleted: completedIssues.count,
                        totalActionsTaken: store.totalActionCount
                    )
                    .plainListRow()
                }
            }
            .tint(Color.afaLightBG)
            .listStyle(.plain)
        }
    }
}

private extension View {
    // Strips default List row chrome (insets, separator, background) so a card
    // can float freely instead of looking like a table row.
    func plainListRow() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct CompletedSectionHeaderCard: View {
    let count: Int
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.afaGreen)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed (\(count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("You've taken action on \(count) campaign\(count == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .accessibilityLabel("Completed, \(count) campaigns")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
    }
}

struct ImpactStatsCard: View {
    let campaignsCompleted: Int
    let totalActionsTaken: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.afaGreen)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("You're making an impact!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.afaGreen)
                Text("\(campaignsCompleted) campaign\(campaignsCompleted == 1 ? "" : "s") completed")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text("\(totalActionsTaken) total action\(totalActionsTaken == 1 ? "" : "s") taken")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.afaGreen.opacity(0.12))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}
