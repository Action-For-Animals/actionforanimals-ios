//
//  IssueDetail.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 8/11/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct AnimalPolicyDetail: View {
    @EnvironmentObject var store: Store
    
    let issue: AnimalPolicy
    
    @State var showLocationSheet = false
    @State private var forceRefreshID = UUID()
    
    // Computed properties that work for both political and corporate campaigns
    var targetedContacts: [Contact] {
        switch issue.contactType {
        case .representatives:
            return issue.contactsForIssue(allContacts: store.state.contacts)
        case .corporate:
            // Fix: Handle optional targets array properly
            guard let targets = issue.targets else { return [] }
            return targets.map { target in
                Contact.fromTarget(target)
            }
        }
    }
    
    // Only relevant for political campaigns
    var irrelevantContacts: [Contact] {
        guard issue.contactType == .representatives else { return [] }
        return issue.irrelevantContacts(allContacts: store.state.contacts)
    }
    
    // Only relevant for political campaigns
    var vacantAreas: [String] {
        guard issue.contactType == .representatives else { return [] }
        return store.state.missingReps.filter { issue.contactAreas.contains($0) || $0 == issue.irrelevantContactArea() }
    }
    
    // Determine if we need location (only for political campaigns)
    var requiresLocation: Bool {
        issue.contactType == .representatives
    }
    
    var hasValidTargets: Bool {
        !targetedContacts.isEmpty
    }
    
    // NEW: Check if this is a batch email campaign
    var isBatchEmailCampaign: Bool {
        issue.contactType == .corporate &&
        issue.actions?.email?.enabled == true &&
        issue.actions?.email?.distributionMethod == "batch"
    }
    
    // NEW: Check if batch campaign has been completed
    var batchCampaignCompleted: Bool {
        guard isBatchEmailCampaign else { return false }
        // For batch campaigns, check if any of the target contacts have been called on
        return targetedContacts.contains { contact in
            store.state.issueCalledOn(issueID: issue.id, contactID: contact.id)
        }
    }

    // Check if we should show low accuracy warning instead of empty contact list
    var shouldShowLowAccuracyWarning: Bool {
        issue.contactType == .representatives &&
        targetedContacts.isEmpty &&
        store.state.lowAccuracyMessage != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(issue.name)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top, 1)
                    .padding(.bottom, 8)
                    
                Text(issue.markdownIssueReason)
                    .padding(.bottom, 16)
                    .accentColor(.afaDarkBlueText)
                
                if requiresLocation && store.state.location == nil {
                    // Show location setup for political campaigns
                    locationSetupSection
                } else {
                    // Show contacts and action buttons
                    contactsSection
                    
                    if hasValidTargets {
                        actionButtonsSection
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: issue.shareURL) {
                    HStack(spacing: 4) {
                        Text(R.string.localizable.share())
                            .fontWeight(.medium)
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .offset(y: -1)
                    }
                }
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            LocationSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .padding(.top, 40)
            Spacer()
        }
        .onAppear {
            forceRefreshID = UUID()
            AnalyticsManager.shared.trackPageview(path: "/issue/\(issue.slug)/")
            // Clear the change indicator when user views the campaign
            store.dispatch(action: .ClearChangedCampaign(issue.id))
        }
    }
    
    // MARK: - Location Setup Section
    private var locationSetupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(R.string.localizable.setLocationHeader())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 6)
            Button(action: {
                showLocationSheet.toggle()
            }, label: {
                PrimaryButton(title: R.string.localizable.setLocationButton(), systemImageName: "location.circle.fill")
            })
        }
    }
    
    // MARK: - Contacts Section
    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(contactsSectionHeader)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
                .padding(.leading, 6)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Show low accuracy warning if no local reps are available due to fallback
                if shouldShowLowAccuracyWarning {
                    lowAccuracyWarningView
                } else {
                    targetedContactsList
                }

                if !irrelevantContacts.isEmpty {
                    Divider()
                    irrelevantContactsList
                }

                if !vacantAreas.isEmpty {
                    Divider()
                    vacantContactsList
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color.afaLightBG)
            }
            .padding(.bottom, 16)
        }
    }
    
    private var contactsSectionHeader: String {
        switch issue.contactType {
        case .representatives:
            return R.string.localizable.repsListHeader()
        case .corporate:
            return R.string.localizable.targetsListHeader()
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // NEW: For batch campaigns, show single action button
            if isBatchEmailCampaign {
                NavigationLink(value: IssueDetailNavModel(issue: issue, contacts: targetedContacts, actionType: .batchEmail)) {
                    PrimaryButton(title: "Take Action", systemImageName: "person.wave.2.fill")
                }
            } else {
                // Original behavior for individual campaigns
                NavigationLink(value: IssueDetailNavModel(issue: issue, contacts: targetedContacts, actionType: getPreferredActionType())) {
                    PrimaryButton(title: "Take Action", systemImageName: "person.wave.2.fill")
                }
            }
            
        }
    }
    
    // MARK: - Helper Methods
    private func getPreferredActionType() -> IssueDetailNavModel.ActionType {
        if issue.contactType == .corporate {
            // For corporate campaigns, prefer email if enabled, otherwise call
            if issue.actions?.email?.enabled == true {
                return .email
            }
        }
        return .call
    }
    
    // MARK: - Contact Lists
    @ViewBuilder
    private var targetedContactsList: some View {
        if isBatchEmailCampaign {
            // For batch campaigns, show single company entry with navigation
            NavigationLink(value: IssueDetailNavModel(issue: issue, contacts: targetedContacts, actionType: .batchEmail)) {
                HStack(spacing: 12) {
                    // Corporate logo placeholder (consistent with contact photos)
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 45, height: 45)
                        .overlay {
                            Image(systemName: "building.2")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .overlay {
                            // Show completion checkmark for batch campaigns
                            if batchCampaignCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.afaGreen)
                                    .background {
                                        Circle().foregroundColor(.white)
                                    }
                                    .offset(x: 20, y: 15)
                                    .accessibilityHidden(true)
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issue.corporateInfo?.company ?? "Company")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if let industry = issue.corporateInfo?.industry {
                            Text(industry)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        } else {
            // Original behavior for individual campaigns
            ForEach(targetedContacts.numbered(), id: \.element.id) { contact in
                NavigationLink(value: IssueDetailNavModel(issue: issue, contacts: Array(targetedContacts[contact.number..<targetedContacts.endIndex]), actionType: getPreferredActionType())) {
                    ContactListItem(
                        contact: contact.element,
                        showComplete: store.state.issueCalledOn(issueID: issue.id, contactID: contact.element.id)
                    )
                    .id(forceRefreshID)
                }
                
                if contact.number < targetedContacts.count - 1 {
                    Divider()
                }
            }
        }
    }
    
    private var irrelevantContactsList: some View {
        ForEach(irrelevantContacts, id: \.id) { contact in
            ContactListItem(
                contact: contact,
                showComplete: store.state.issueCalledOn(issueID: issue.id, contactID: contact.id),
                contactNote: R.string.localizable.irrelevantContactMessage()
            )
            .opacity(0.4)
            .id(forceRefreshID)
            
            if contact.id != irrelevantContacts.last?.id {
                Divider()
            }
        }
    }
    
    private var vacantContactsList: some View {
        ForEach(vacantAreas, id: \.self) { area in
            let contact = Contact(area: area, name: R.string.localizable.vacantSeatTitle())
            let note = R.string.localizable.vacantSeatMessage(area)
            
            ContactListItem(
                contact: contact,
                contactNote: note
            )
            .opacity(0.4)
            
            if area != vacantAreas.last {
                Divider()
            }
        }
    }

    // Warning view when local reps aren't available due to low accuracy location
    private var lowAccuracyWarningView: some View {
        VStack(spacing: 16) {
            // Location pin icon in light blue circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "location.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding(.top, 16)

            VStack(spacing: 8) {
                // Main heading
                Text("We need a more specific address")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }

            // Update Location button
            Button(action: { showLocationSheet.toggle() }) {
                HStack {
                    Text("Update Location")
                        .font(.system(.title3))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Image(systemName: "location.magnifyingglass")
                        .imageScale(.large)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.blue)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let store: Store = {
        let state = AppState()
        state.contacts = [.housePreviewContact, .senatePreviewContact1, .senatePreviewContact2, .unknownMayorPreviewContact]
        return Store(state: state)
    }()
    
    AnimalPolicyDetail(issue: .houseOnlyPreviewIssue)
        .environmentObject(store)
}

// MARK: - Updated Navigation Model
struct IssueDetailNavModel {
    var issue: AnimalPolicy
    let contacts: [Contact]
    let actionType: ActionType
    
    enum ActionType {
        case call
        case email
        case batchEmail // NEW: For batch corporate campaigns
    }
}

extension IssueDetailNavModel: Equatable, Hashable {
    static func == (lhs: IssueDetailNavModel, rhs: IssueDetailNavModel) -> Bool {
        return lhs.issue.id == rhs.issue.id &&
               lhs.contacts.elementsEqual(rhs.contacts) &&
               lhs.actionType == rhs.actionType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(issue.id)
        hasher.combine(contacts.compactMap({$0.id}).joined())
        hasher.combine(actionType)
    }
}

// Secondary button component for email actions
struct SecondaryButton: View {
    let title: String
    let systemImageName: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImageName)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .foregroundColor(.primary)
        .cornerRadius(8)
    }
}
