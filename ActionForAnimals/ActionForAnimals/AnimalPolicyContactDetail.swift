//
//  IssueContactDetail.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 8/11/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct AnimalPolicyContactDetail: View {
    @EnvironmentObject var store: Store

    let issue: AnimalPolicy
    let remainingContacts: [Contact]
    let actionType: IssueDetailNavModel.ActionType
    
    var currentContact: Contact {
        return remainingContacts.first!
    }
    
    var nextContacts: [Contact] {
        return Array(remainingContacts.dropFirst())
    }
    
    // NEW: Check if this is a batch email campaign
    var isBatchEmailCampaign: Bool {
        actionType == .batchEmail
    }
    
    var issueMarkdown: AttributedString {
        // For batch campaigns, use the first target for script generation
        if isBatchEmailCampaign, let targets = issue.targets, let firstTarget = targets.first {
            return issue.markdownScript(for: actionType, target: firstTarget, location: store.state.location)
        } else if issue.contactType == .corporate, let targets = issue.targets,
           let target = targets.first(where: { $0.name == currentContact.name }) {
            return issue.markdownScript(for: actionType, target: target, location: store.state.location)
        } else {
            return issue.markdownScript(for: actionType, contact: currentContact, location: store.state.location)
        }
    }

    @State private var copiedContactInfo: String?
    @AccessibilityFocusState private var isCopiedContactInfoFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(issue.name)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.bottom, 16)
                
                // NEW: Different contact display for batch vs individual
                Group {
                    if isBatchEmailCampaign {
                        batchCampaignInfoView
                    } else {
                        ContactListItem(contact: currentContact)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.afaLightBG)
                            }
                    }
                }
                .padding(.bottom)
                
                // Contact method section (phone, email, or batch email)
                contactMethodSection
                
                Text(issueMarkdown)
                    .padding(.bottom)
                
                OutcomesView(outcomes: getOutcomesForActionType(), report: { outcome in
                    let log = ContactLog(issueId: String(issue.id), contactId: currentContact.id, phone: "", outcome: outcome.status, date: Date(), reported: true, actionType: actionType == .email || actionType == .batchEmail ? "email" : "call")
                    store.dispatch(action: .ReportOutcome(issue, log, outcome))
                    
                    // For batch campaigns, go to completion screen since there's no "next" contact
                    if isBatchEmailCampaign {
                        store.dispatch(action: .GoToNext(issue, [], actionType))  // Empty array means go to completion
                    } else {
                        store.dispatch(action: .GoToNext(issue, nextContacts, actionType))
                    }
                })
                Spacer()
            }
            .padding(.horizontal)
        }
        .clipped()
    }
    
    // NEW: Company info view for batch campaigns
    private var batchCampaignInfoView: some View {
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
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color.afaLightBG)
        }
    }

    @ViewBuilder
    private var contactMethodSection: some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                if let copiedContactInfo {
                    Text(actionType == .email || actionType == .batchEmail ?
                         "Copied: \(copiedContactInfo)" :
                         R.string.localizable.copiedPhone(copiedContactInfo))
                        .bold()
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .accessibilityFocused($isCopiedContactInfoFocused)
                        .accessibilityLabel(actionType == .email || actionType == .batchEmail ?
                                          "Copied email information" :
                                          R.string.localizable.a11yCopiedPhoneNumber())
                    Spacer()
                }

                if actionType == .email {
                    // Individual email link
                    if let email = currentContact.email, !email.isEmpty {
                        Text(email)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.afaDarkBlueText)
                            .onTapGesture {
                                self.openEmail(email: email)
                            }
                            .onLongPressGesture(minimumDuration: 1.0) {
                                copyContactInfo(email)
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Tap to open email app, long press to copy email address")
                    } else {
                        Text("No email available")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondary)
                    }
                } else if actionType == .batchEmail {
                    // NEW: Batch email compose button
                    Button(action: {
                        self.openBatchEmail()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                            Text("Compose Email")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.afaDarkBlue)
                        .cornerRadius(8)
                    }
                    .onLongPressGesture(minimumDuration: 1.0) {
                        let emailList = getAllTargetEmails()
                        copyContactInfo(emailList)
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Tap to open email app, long press to copy all email addresses")
                } else {
                    // Phone number (unchanged)
                    Text(currentContact.phone)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.afaDarkBlueText)
                        .onTapGesture {
                            self.call(phoneNumber: currentContact.phone)
                        }
                        .onLongPressGesture(minimumDuration: 1.0) {
                            copyContactInfo(currentContact.phone)
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(R.string.localizable.a11yPhoneCallCopyHint())

                    // Field offices (only for political contacts)
                    if currentContact.contactType == .representatives && currentContact.fieldOffices.count >= 1 {
                        Menu {
                            ForEach(currentContact.fieldOffices) { office in
                                if #available(iOS 16.4, *) {
                                    ControlGroup {
                                        MenuButtonsView(office: office, copiedContactInfo: $copiedContactInfo,
                                                        isCopiedContactInfoFocused: _isCopiedContactInfoFocused, call: call)
                                    }
                                } else {
                                    MenuButtonsView(office: office, copiedContactInfo: $copiedContactInfo,
                                                    isCopiedContactInfoFocused: _isCopiedContactInfoFocused, call: call)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(Color.afaDarkBlue)
                                .padding(.leading, 4)
                        }
                        .accessibilityIdentifier("localNumbers")
                    }
                }
            }
        }
        .padding(.bottom)
    }

    private func copyContactInfo(_ info: String) {
        UIPasteboard.general.string = info
        withAnimation {
            copiedContactInfo = info
            if UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5) {
                    isCopiedContactInfoFocused = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) {
            withAnimation {
                isCopiedContactInfoFocused = false
                copiedContactInfo = nil
            }
        }
    }

    private func call(phoneNumber: String) {
        let telephone = "tel://"
        let formattedString = telephone + phoneNumber
        guard let url = URL(string: formattedString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openEmail(email: String) {
        let subject = getEmailSubject()
        let body = getEmailBody()
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        guard let url = URL(string: mailtoString) else { return }
        UIApplication.shared.open(url)
    }
    
    // NEW: Open batch email with all targets
    private func openBatchEmail() {
        let allEmails = getAllTargetEmails()
        let subject = getEmailSubject()
        let body = getEmailBody()
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Put all emails in the "to" field
        let mailtoString = "mailto:\(allEmails)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        guard let url = URL(string: mailtoString) else { return }
        UIApplication.shared.open(url)
    }
    
    // NEW: Get all target emails as comma-separated string
    private func getAllTargetEmails() -> String {
        return remainingContacts.compactMap { $0.email }.joined(separator: ",")
    }
    
    private func getEmailSubject() -> String {
        if let emailAction = issue.actions?.email {
            return emailAction.subject
        }
        return "Action for Animals Campaign"
    }
    
    private func getEmailBody() -> String {
        // Use the same script processing but get the plain text version
        let attributedString = issueMarkdown
        return String(attributedString.characters)
    }
    
    private func getOutcomesForActionType() -> [Outcome] {
        switch actionType {
        case .call:
            return [
                Outcome(label: "Unavailable", status: "unavailable"),
                Outcome(label: "Voicemail", status: "voicemail"),
                Outcome(label: "Made Contact", status: "contact"),
                Outcome(label: "Skip", status: "skip")
            ]
        case .email:
            return [
                Outcome(label: "Sent Email", status: "contact"),
                Outcome(label: "Skip", status: "skip")
            ]
        case .batchEmail:
            return [
                Outcome(label: "Sent Email", status: "contact"),
                Outcome(label: "Skip", status: "skip")
            ]
        }
    }
}

struct MenuButtonsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let office: AreaOffice
    @Binding var copiedContactInfo: String?
    @AccessibilityFocusState var isCopiedContactInfoFocused: Bool
    let call: (String) -> Void

    var body: some View {
        Button {
            self.call(office.phone)
        } label: {
            if dynamicTypeSize >= .accessibility1 {
                Text(R.string.localizable.a11yOfficeCallPhoneNumber(office.city, office.phone))
            } else {
                Image(systemName: "phone")
                Text(office.city)
            }
        }
        .accessibilityLabel(R.string.localizable.a11yOfficeCallPhoneNumber(office.city, office.phone))
        .accessibilityHint(R.string.localizable.a11yPhoneCallHint())

        if #available(iOS 16.4, *) {
            Button {
                UIPasteboard.general.string = office.phone
                withAnimation {
                    copiedContactInfo = office.phone
                    if UIAccessibility.isVoiceOverRunning {
                        isCopiedContactInfoFocused = true
                    }
                }

                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) {
                    withAnimation {
                        isCopiedContactInfoFocused = false
                        copiedContactInfo = nil
                    }
                }
            } label: {
                if dynamicTypeSize >= .accessibility1 {
                    Text(R.string.localizable.a11yOfficeCopyPhoneNumber(office.city, office.phone))
                } else {
                    Image(systemName: "doc.on.doc")
                    Text(R.string.localizable.copy())
                }
            }
            .accessibilityLabel(R.string.localizable.a11yOfficeCopyPhoneNumber(office.city, office.phone))
            .accessibilityHint(R.string.localizable.a11yPhoneCopyHint())
        }
    }
}

#Preview {
    AnimalPolicyContactDetail(issue: AnimalPolicy.basicPreviewIssue, remainingContacts: [Contact.housePreviewContact, Contact.senatePreviewContact1], actionType: .call)
        .environmentObject(Store(state: AppState()))
}
