//
//  IssueListItem.swift
//  ActionForAnimals
//

import SwiftUI

struct AnimalPolicyListItem: View {
    let issue: AnimalPolicy
    let contacts: [Contact]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                
                // Existing: contacts row + subtitle
                HStack(spacing: 0) {
                    let contactsForIssue = contacts.isEmpty
                    ? issue.contactAreas.flatMap { Contact.placeholderContact(for: $0) }
                    : issue.contactsForIssue(allContacts: contacts)

                    ForEach(contactsForIssue.numbered()) { numberedContact in
                        ContactCircle(contact: numberedContact.element, issueID: issue.id)
                            .frame(width: usingRegularFonts() ? 20 : 40,
                                   height: usingRegularFonts() ? 20 : 40)
                            .offset(x: -10 * CGFloat(numberedContact.number), y: 0)
                    }
                    
                    Text(callsSubtitle(for: issue))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .offset(x: contactsForIssue.isEmpty ? 0 : 16 + (-10 * CGFloat(contactsForIssue.count)), y: 0)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // full-row tap target when wrapped in NavigationLink
    }

    private func callsSubtitle(for issue: AnimalPolicy) -> String {
        let calls = issue.stats.calls
        let pretty = calls.formatted(.number.notation(.compactName)) // 1.2K, 12K, etc.
        return String(format: R.string.localizable.policyItemCallsMade(pretty))
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
                    .padding(badgeSize * ((1 - iconScale) / 2))
                    .frame(width: badgeSize, height: badgeSize)
                    .completionCheckmarkOverlay(show: isSuccess, containerSize: badgeSize, mode: .overlay)
                    .padding(.vertical, 2)
                    .accessibilityHidden(true)

            }
            .accessibilityLabel(categoryAccessibilityLabel(for: issue))
    }
    
    // MARK: Visual mapping
    private func categoryIconName(for issue: AnimalPolicy) -> String {
        // For now, hard-code farmed. Expand the switch as you add more categories.
        /*
        switch primaryCategoryKey(from: issue) {
        case .farmed:   return "category-farmed"
        case .wildlife: return "category-wildlife"
        case .oceans:   return "category-oceans"
        case .policy:   return "category-policy"
        case .none:     return "category-default"
        }
        */
        return "category-farmed"
    }
    
    private func primaryCategoryKey(from issue: AnimalPolicy) -> CategoryKey {
           guard let raw = issue.categories.first?.name.lowercased() else { return .none }

           if raw.contains("farmed") { return .farmed }
           if raw.contains("wild")   { return .wildlife }
           if raw.contains("ocean") || raw.contains("marine") { return .oceans }
           if raw.contains("policy") || raw.contains("legis") { return .policy }
           return .none
    }

    
    private func initials(from text: String) -> String {
        let words = text.split(separator: " ").prefix(2)
        return words.compactMap { $0.first?.uppercased() }.joined()
    }

    private func categoryAccessibilityLabel(for issue: AnimalPolicy) -> String {
        if let name = issue.categories.first?.name, !name.isEmpty {
            return name
        }
        return R.string.localizable.menuAbout() // or a generic “Issue”
    }
}

private enum CategoryKey {
    case farmed, wildlife, oceans, policy, none
}

