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

            IssuesList(store: store, selectedIssue: $selectedIssue, searchText: $searchText)
        }
        .navigationBarHidden(true)
        .onAppear() {
            AnalyticsManager.shared.trackPageview(path: "/")

            if let location = store.state.location, store.state.contacts.isEmpty {
                store.dispatch(action: .FetchContacts(location))
            }
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
    @State var showRemindersSheet = false
    @State var showAboutSheet = false
    var showingWelcomeScreen: Bool

    var body: some View {
        Menu {
            Button { showRemindersSheet.toggle() } label: {
                Text(R.string.localizable.menuScheduledReminders())
            }
            Button { showAboutSheet.toggle() } label: {
                Text(R.string.localizable.menuAbout())
            }
        } label: {
            Image(systemName: "gear")
                .renderingMode(.template)
                .font(.title)
                .accessibilityLabel(Text(R.string.localizable.menuName))
        }
        .sheet(isPresented: $showRemindersSheet) {
            ScheduleReminders()
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
    }
}

struct IssuesList: View {
    @ObservedObject var store: Store
    @Binding var selectedIssue: AnimalPolicy?
    @Binding var searchText: String
    
    var isSearching: Bool {
        searchText.count >= 3
    }

    // Always show ALL issues (active + inactive) by default
    var allIssues: [AnimalPolicy] {
        if isSearching {
            let filtered = store.state.issues.filter { issue in
                issue.name.localizedCaseInsensitiveContains(searchText) ||
                issue.reason.localizedCaseInsensitiveContains(searchText) ||
                issue.script.localizedCaseInsensitiveContains(searchText) ||
                issue.slug.localizedCaseInsensitiveContains(searchText) ||
                issue.categories.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
            
            // Sort so that name matches come first
            return filtered.sorted { a, b in
                let am = a.name.localizedCaseInsensitiveContains(searchText)
                let bm = b.name.localizedCaseInsensitiveContains(searchText)
                return am && !bm
            }
        } else {
            return store.state.issues
        }
    }

    var body: some View {
        if isSearching && allIssues.isEmpty {
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
        } else {
            // Flat list, no categories, no footer toggle
            List(allIssues, selection: $selectedIssue) { issue in
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

