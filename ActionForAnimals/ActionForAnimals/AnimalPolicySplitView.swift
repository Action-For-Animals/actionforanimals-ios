//
//  IssueSplitView.swift
//  ActionForAnimals
//
//  Created by Christopher Selin on 11/1/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct AnimalPolicySplitView: View {
    @EnvironmentObject var store: Store
    @Environment(\.horizontalSizeClass) private var originalSizeClass
    @State private var pendingDeepLinkSlug: String?

    var body: some View {
        TabView(selection: $store.state.selectedTab) {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                Dashboard(selectedIssue: $store.state.issueRouter.selectedIssue)
                    .navigationSplitViewColumnWidth(ideal: 375)
            } detail: {
                NavigationStack(path: $store.state.issueRouter.path) {
                    if let selectedIssue = store.state.issueRouter.selectedIssue {
                        // Use fresh data from store to fix iPad stale content issue
                        let issueToShow = store.state.issues.first(where: { $0.id == selectedIssue.id }) ?? selectedIssue
                        AnimalPolicyDetail(issue: issueToShow)
                            .toolbar(.hidden, for: .tabBar)
                            .onChange(of: selectedIssue.id) { newIssueId in
                                // Clear the green dot when campaign is selected on iPad
                                store.dispatch(action: .ClearChangedCampaign(newIssueId))
                            }
                            .navigationDestination(for: IssueDetailNavModel.self) { idnm in
                                AnimalPolicyContactDetail(issue: idnm.issue, remainingContacts: idnm.contacts, actionType: idnm.actionType)
                            }
                            .navigationDestination(for: IssueDoneNavModel.self) { inm in
                                AnimalPolicyDone(issue: inm.issue)
                            }
                    } else {
                        VStack(alignment: .leading) {
                            Text(R.string.localizable.choosePolicyPlaceholder())
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(R.string.localizable.choosePolicySubheading())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationSplitViewStyle(.balanced)
            .tabItem({ Label("Campaigns", systemImage: "phone.bubble.fill" ) })
            .tag("issues")
            // Set the inner size class for the navigation stack back to whatever it was originally since we override it for old tab bar behavior below
            .environment(\.horizontalSizeClass, originalSizeClass)
            .toolbar(.visible, for: .tabBar)
            
            InboxView()
                .tabItem({ Label(R.string.localizable.tabReps(), systemImage: "person.crop.circle.fill.badge.checkmark") })
                .tag("inbox")

            MonthlyLeagueView()
                .tabItem({ Label("Leagues", systemImage: "trophy.fill") })
                .tag("leagues")
        }// the new TabBar style in iOS 18 does not work well with this style, for now override the size class so it uses the old style on iPadOS
        .environment(\.horizontalSizeClass, .compact)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL,
                  url.pathComponents.count >= 3,
                  url.pathComponents[1] == "campaign" else { return }
            let slug = url.pathComponents[2]
            store.state.selectedTab = "issues"
            if let issue = store.state.issues.first(where: { $0.slug == slug }) {
                store.state.issueRouter.selectedIssue = issue
            } else {
                pendingDeepLinkSlug = slug
            }
        }
        .onChange(of: store.state.issues) { issues in
            guard let slug = pendingDeepLinkSlug,
                  let issue = issues.first(where: { $0.slug == slug }) else { return }
            store.state.issueRouter.selectedIssue = issue
            pendingDeepLinkSlug = nil
        }
        .sheet(isPresented: $store.state.showYourImpact) {
            YourImpact()
                .environmentObject(store)
                .onDisappear {
                    store.state.showYourImpact = false
                }
        }
    }
}

struct IssueSplitView_Previews: PreviewProvider {
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
        AnimalPolicySplitView().environmentObject(store)
    }
}
