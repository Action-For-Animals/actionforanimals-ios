//
//  IssueListItem.swift
//  ActionForAnimals
//

import SwiftUI

struct AnimalPolicyListItem: View {
    let issue: AnimalPolicy
    let contacts: [Contact]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject var store: Store

    private func usingRegularFonts() -> Bool {
        dynamicTypeSize < .accessibility3
    }

    var body: some View {
                
        // drive UI from `status` instead of `active`
        let status = issue.status.lowercased()
        let isActive = (status == "active")

        HStack(alignment: .center, spacing: 12) {
            // Category Badge with status styling
            CategoryBadge(issue: issue,
                          dynamicTypeSize: dynamicTypeSize,
                          status: status)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(issue.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Enhanced: contacts row + subtitle with campaign type
                HStack(spacing: 0) {
                    let contactsForIssue = getContactsForDisplay()

                    ForEach(contactsForIssue.numbered()) { numberedContact in
                        ContactCircle(contact: numberedContact.element, issueID: issue.id)
                            .frame(width: usingRegularFonts() ? 20 : 40,
                                   height: usingRegularFonts() ? 20 : 40)
                            .offset(x: -10 * CGFloat(numberedContact.number), y: 0)
                    }
                    
                    // Campaign type label + stats
                    HStack(spacing: 4) {
                        CampaignTypeLabel(issue: issue)
                        
                        Text(callsSubtitle(for: issue))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .offset(x: contactsForIssue.isEmpty ? 0 : 16 + (-10 * CGFloat(contactsForIssue.count)), y: 0)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // full-row tap target when wrapped in NavigationLink
    }

    private func getContactsForDisplay() -> [Contact] {
        if issue.contactType == .corporate {
            // For batch email campaigns, show single company contact
            if issue.isBatchEmailCampaign {
                // Create a single contact representing the company
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
                // For individual corporate campaigns, create contacts from targets
                guard let targets = issue.targets else { return [] }
                return targets.map { Contact.fromTarget($0) }
            }
        } else {
            // For political campaigns, use existing logic
            return contacts.isEmpty
                ? issue.contactAreas.flatMap { Contact.placeholderContact(for: $0) }
                : issue.contactsForIssue(allContacts: contacts)
        }
    }

    private func callsSubtitle(for issue: AnimalPolicy) -> String {
        // Use updated count from issueCallCounts if available, otherwise use original count
        let totalActions = store.state.issueCallCounts[issue.id] ?? issue.totalActionCount
        
        // Format number with compact notation (1.2K, 12K, etc.)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let pretty: String
        if totalActions >= 1000 {
            let thousands = Double(totalActions) / 1000.0
            pretty = "\(formatter.string(from: NSNumber(value: thousands)) ?? "0")K"
        } else {
            pretty = "\(totalActions)"
        }
        
        return "• \(pretty) actions taken"
    }
    
    // unchanged
    private var repText: String {
        if issue.contactAreas.isEmpty {
            return R.string.localizable.noContacts()
        } else {
            let areas = issue.contactAreas.map { AreaToNiceString(area: $0) }.joined(separator: ", ")
            return R.string.localizable.callAreas(areas)
        }
    }
}

// MARK: - Campaign Type Label Component
private struct CampaignTypeLabel: View {
    let issue: AnimalPolicy
    
    var body: some View {
        Text(labelText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
    
    private var labelText: String {
        // Determine action type based on enabled actions
        if issue.actions?.call?.enabled == true {
            return "Call"
        } else if issue.actions?.email?.enabled == true {
            return "Email"
        } else {
            // If no actions defined, return generic label
            return "Action"
        }
    }
    
    private var backgroundColor: Color {
        if issue.actions?.call?.enabled == true {
            return Color.orange.opacity(0.15)
        } else if issue.actions?.email?.enabled == true {
            return Color.teal.opacity(0.15)
        } else {
            // Fallback for generic "Action"
            return Color.gray.opacity(0.15)
        }
    }
    
    private var textColor: Color {
        if issue.actions?.call?.enabled == true {
            return Color.orange.opacity(0.8)
        } else if issue.actions?.email?.enabled == true {
            return Color.teal.opacity(0.8)
        } else {
            // Fallback for generic "Action"
            return Color.gray.opacity(0.8)
        }
    }
}

private struct CategoryBadge: View {
    let issue: AnimalPolicy
    let dynamicTypeSize: DynamicTypeSize
    let status: String   // pass full status

    private var badgeSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5, .accessibility4: return 60
        case .accessibility3, .accessibility2: return 52
        default: return 48
        }
    }

    var body: some View {
        let iconScale: CGFloat = 0.88   // 86–90% usually looks best
        let iconName = categoryIconName(for: issue)
        let isActive = (status == "active")
        let isSuccess = (status == "success")
        
        ZStack(alignment: .bottomTrailing) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .saturation(isActive ? 1 : 0)
                    .opacity(isActive ? 1 : 0.75)
                    .padding(badgeSize *  ((1 - iconScale) / 2))
                    .frame(width: badgeSize, height: badgeSize)
                    .completionCheckmarkOverlay(show: isSuccess, containerSize: badgeSize, mode: .overlay)
                    .padding(.vertical, 2)
                    .accessibilityHidden(true)

            }
            .accessibilityLabel(categoryAccessibilityLabel(for: issue))
    }
    
    // MARK: Visual mapping - now uses CategoryHelper
    private func categoryIconName(for issue: AnimalPolicy) -> String {
        return CategoryHelper.iconName(for: issue)
    }

    private func primaryCategoryKey(from issue: AnimalPolicy) -> CategoryKey {
        return CategoryHelper.primaryCategoryKey(from: issue)
    }

    private func categoryAccessibilityLabel(for issue: AnimalPolicy) -> String {
        if let name = issue.categories.first?.name, !name.isEmpty {
            return name
        }
        return R.string.localizable.menuAbout() // or a generic "Issue"
    }
}

