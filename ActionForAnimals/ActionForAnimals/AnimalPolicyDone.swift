//
//  IssueDone.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 10/2/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI
import StoreKit
import OneSignal

struct AnimalPolicyDone: View {
    @EnvironmentObject var store: Store
    @Environment(\.openURL) private var openURL
    
    @State var showNotificationAlert = false
    
    let issue: AnimalPolicy

    init(issue: AnimalPolicy) {
        self.issue = issue
    }

    let donateURL = URL(string: "https://secure.actblue.com/donate/5calls-donate?refcode=ios&refcode2=\(AnalyticsManager.shared.callerID)")!

    func latestOutcomeForContact(contact: Contact, issueCompletions: [ContactLog]) -> String {
        // For corporate campaigns, handle completion tracking differently
        if issue.contactType == .corporate {
            // For batch campaigns, check the actual outcome status
            if issue.isBatchEmailCampaign {
                if let contactLog = issueCompletions.last {
                    if contactLog.outcome == "contact" {
                        return "Sent Email"
                    } else {
                        return ContactLog.localizedOutcomeForStatus(status: contactLog.outcome)
                    }
                }
                return R.string.localizable.outcomesSkip()
            } else {
                // For individual corporate campaigns, look for this specific contact ID (get the most recent one)
                if let contactLog = issueCompletions.last(where: { $0.contactId == contact.id }) {
                    if contactLog.outcome == "contact" {
                        return contactLog.actionType == "email" ? "Sent Email" : "Made Contact"
                    } else {
                        return ContactLog.localizedOutcomeForStatus(status: contactLog.outcome)
                    }
                }
            }
            return R.string.localizable.outcomesSkip()
        }
        
        // Original logic for political campaigns
        if let contactLog = issueCompletions.last(where: { $0.contactId == contact.id }) {
            if contactLog.outcome == "contact" {
                return contactLog.actionType == "email" ? "Sent Email" : "Made Contact"
            } else {
                return ContactLog.localizedOutcomeForStatus(status: contactLog.outcome)
            }
        }

        return R.string.localizable.outcomesSkip()
    }

    func shouldShowImage(latestOutcomeForContact: String) -> Bool {
        return latestOutcomeForContact != "Skip"
    }

    var shareMessageText: String {
        let message: String
        if let issueCalls = store.state.issueCallCounts[issue.id], issueCalls > 0 {
            message = "I just joined \(issueCalls) others speaking up for animals on \"\(issue.name)\" — add your voice too:"
        } else {
            message = "I just took action for animals on \"\(issue.name)\" — add your voice too:"
        }
        return "\(message)\n\(issue.shareURL.absoluteString)"
    }

    private var celebrationCard: some View {
        VStack(spacing: 16) {
            Text("Nice work!")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)

            Text("Campaign complete")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)

            ShareLink(item: shareMessageText) {
                HStack(spacing: 6) {
                    Text("Share this campaign")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.bold)
                }
                .foregroundColor(.afaDarkBlue)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background {
                    Capsule()
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .accessibilityLabel(Text("\(R.string.localizable.shareThisTopic()): \(issue.name)"))
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .background {
            Image("sanctuary-empty")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.afaGreen.opacity(0.3), radius: 12, x: 0, y: 6)
        .overlay(alignment: .top) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                Image("animals-high-five")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
            .offset(y: -32)
        }
    }

    var getContactsToDisplay: () -> [Contact] {
        return {
            if issue.contactType == .corporate {
                // For corporate campaigns, show targets as contacts
                if issue.isBatchEmailCampaign {
                    // For batch campaigns, show single company contact
                    let companyName = issue.corporateInfo?.company ?? "Company"
                    return [Contact(
                        id: "company-\(issue.id)",
                        name: companyName,
                        phone: "",
                        email: "",
                        contactType: .corporate,
                        metadata: nil
                    )]
                } else {
                    // For individual corporate campaigns, show all targets
                    guard let targets = issue.targets else { return [] }
                    return targets.map { Contact.fromTarget($0) }
                }
            } else {
                // For political campaigns, use existing logic
                return issue.contactsForIssue(allContacts: store.state.contacts)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                celebrationCard
                    .padding(.top, 28)
                    .padding(.bottom, 16)

                HStack(spacing: 10) {
                    StatTile(value: store.state.globalCallCount, title: R.string.localizable.totalCalls())
                    if let issueCalls = store.state.issueCallCounts[issue.id] {
                        StatTile(value: issueCalls, title: R.string.localizable.totalPolicyCalls())
                    }
                }
                .padding(.bottom, 14)

                Text(R.string.localizable.contactSummaryHeader())
                    .font(.caption).fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                ForEach(getContactsToDisplay()) { contact in
                    let issueCompletions = store.state.issueCompletion[issue.id] ?? []
                    let latestContactCompletion = latestOutcomeForContact(contact: contact, issueCompletions: issueCompletions)
                    ContactListItem(contact: contact, showComplete: shouldShowImage(latestOutcomeForContact: latestContactCompletion), contactNote: latestContactCompletion, listType: .compact)
                }
                if store.state.donateOn {
                    Text(R.string.localizable.support5calls())
                        .font(.caption).fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        Text(R.string.localizable.support5callsSub())
                        Button(action: {
                            openURL(donateURL)
                        }) {
                            PrimaryButton(title: R.string.localizable.donateToday(), systemImageName: "hand.thumbsup.circle.fill", bgColor: .afaRed)
                        }
                    }
                    .padding(.bottom, 16)
                }

                Button(action: {
                    store.dispatch(action: .GoToRoot)
                }, label: {
                    PrimaryButton(title: R.string.localizable.doneScreenButton(), systemImageName: "flag.checkered")
                })
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
        .clipped()
        .frame(maxWidth: 500)
        .onAppear() {
            AnalyticsManager.shared.trackPageview(path: "/issue/\(issue.slug)/done/")

            store.dispatch(action: .FetchStats(issue.id))
          
            // will prompt for a rating after hitting done 5 times
            RatingPromptCounter.increment {
                guard let currentScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                
                SKStoreReviewController.requestReview(in: currentScene)
            }
            
            // unlikely to occur at the same time as the rating prompt counter
            checkForNotifications()
        }.alert(R.string.localizable.notificationTitle(), isPresented: $showNotificationAlert) {
            Button {
                // we don't really care which issue they were on when they subbed, just that it was a done page
                OneSignal.promptForPushNotifications(userResponse: { success in
                    if success {
                        AnalyticsManager.shared.trackEvent(name: "push-subscribe", path: "/issue/x/done/")
                    }
                })
            } label: {
                Text(R.string.localizable.notificationImportant())
            }
            Button {
                let key = UserDefaultsKey.lastAskedForNotificationPermission.rawValue
                UserDefaults.standard.set(Date(), forKey: key)
            } label: {
                Text(R.string.localizable.notificationNone())
            }
        } message: {
            Text(R.string.localizable.notificationAsk())
        }

    }
}

extension AnimalPolicyDone {
    func checkForNotifications() {
            let deviceState = OneSignal.getDeviceState()
            let nextPrompt = nextNotificationPromptDate() ?? Date()

            if deviceState?.hasNotificationPermission == false && nextPrompt <= Date() {
                showNotificationAlert = true
            }
        }
    func nextNotificationPromptDate() -> Date? {
        let key = UserDefaultsKey.lastAskedForNotificationPermission.rawValue
        guard let lastPrompt = UserDefaults.standard.object(forKey: key) as? Date else { return nil }

        return Calendar.current.date(byAdding: .month, value: 1, to: lastPrompt)
    }
}

struct StatTile: View {
    let value: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value, format: .number)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.afaDarkBlue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.afaGreen.opacity(0.12))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let previewState = {
        let state = AppState()
        state.contacts = [.housePreviewContact, .senatePreviewContact1, .senatePreviewContact2]
        state.issueCompletion[AnimalPolicy.basicPreviewIssue.id] = [
            ContactLog(issueId: String(AnimalPolicy.basicPreviewIssue.id), contactId: Contact.housePreviewContact.id, phone: "", outcome: "voicemail", date: Date(), reported: true, actionType: "call", animalsHelped: 1, category: "farmed"),
            ContactLog(issueId: String(AnimalPolicy.basicPreviewIssue.id), contactId: Contact.senatePreviewContact1.id, phone: "", outcome: "contact", date: Date(), reported: true, actionType: "call", animalsHelped: 1, category: "farmed")
        ]
        return state
    }()

    AnimalPolicyDone(issue: .basicPreviewIssue)
        .environmentObject(Store(state: previewState, middlewares: [appMiddleware()]))
}

struct IssueDoneNavModel {
    let issue: AnimalPolicy
    let type: String
}

extension IssueDoneNavModel: Equatable, Hashable {
    static func == (lhs: IssueDoneNavModel, rhs: IssueDoneNavModel) -> Bool {
        return lhs.issue.id == rhs.issue.id && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(issue.id)
        hasher.combine(type)
    }
}
