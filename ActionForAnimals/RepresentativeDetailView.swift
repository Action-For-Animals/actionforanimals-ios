//
//  RepresentativeDetailView.swift
//  ActionForAnimals
//
//  Created by Amit Dhuleshia on 9/25/25.
//  Copyright © 2025 Action For Animals. All rights reserved.
//

import SwiftUI

struct RepresentativeDetailView: View {
    let contact: Contact

    @State private var copiedContactInfo: String?
    @AccessibilityFocusState private var isCopiedContactInfoFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var headerSection: some View {
        HStack {
            Spacer()

            Text("Representative Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.afaDarkBlue)
    }

    private var representativeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ContactCircle(contact: contact)
                    .frame(width: 45, height: 45)
                    .padding(.vertical, 8)
                    .padding(.leading, 8)
                    .padding(.trailing, 0)

                VStack(alignment: .leading) {
                    HStack {
                        Text(contact.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primary)

                        // Party affiliation badge
                        if !partyInitial.isEmpty {
                            Text(partyInitial)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(partyColor)
                                .clipShape(Circle())
                        }
                    }

                    Text(contact.officeDescription())
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }

        }
        .padding(2)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var partyInitial: String {
        switch contact.party.lowercased() {
        case "democrat", "democratic":
            return "D"
        case "republican":
            return "R"
        case "independent":
            return "I"
        default:
            return ""
        }
    }

    private var partyColor: Color {
        switch contact.party.lowercased() {
        case "democrat", "democratic":
            return .blue
        case "republican":
            return .red
        case "independent":
            return .purple
        default:
            return .gray
        }
    }


    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().background(Color.afaLightGray)

            // Light gray background like Settings
            ScrollView {
                VStack(spacing: 20) {
                    // Profile section (no card background)
                    profileSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    // Contact Information section
                    VStack(alignment: .leading, spacing: 8) {
                        // Header
                        HStack {
                            Text("Contact Information")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        // Contact methods in white card
                        VStack(spacing: 0) {
                            contactMethodsCards
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            ContactCircle(contact: contact)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)

                    // Party affiliation badge
                    if !partyInitial.isEmpty {
                        Text(partyInitial)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(partyColor)
                            .clipShape(Circle())
                    }
                }

                Text(contact.officeDescription())
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
    }

    private var contactMethodsCards: some View {
        VStack(spacing: 0) {
            // Phone card
            if !contact.phone.isEmpty {
                ContactRowCard(
                    icon: "phone.fill",
                    iconColor: .green,
                    title: "Phone",
                    value: contact.phone,
                    action: { call(phoneNumber: contact.phone) },
                    hasMenu: !contact.fieldOffices.isEmpty,
                    menuContent: {
                        ForEach(contact.fieldOffices) { office in
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
                    }
                )

                // Divider between cards
                if let email = contact.email, !email.isEmpty {
                    Divider()
                        .padding(.leading, 60)
                }
            }

            // Email card
            if let email = contact.email, !email.isEmpty {
                ContactRowCard(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "Email",
                    value: email,
                    action: { openEmail(email: email) },
                    hasMenu: false,
                    menuContent: { EmptyView() }
                )
            }
        }
    }


    // Helper functions for contact actions
    private func call(phoneNumber: String) {
        let telephone = "tel://"
        let formattedString = telephone + phoneNumber
        guard let url = URL(string: formattedString) else { return }
        UIApplication.shared.open(url)
    }

    private func openEmail(email: String) {
        let mailtoString = "mailto:\(email)"
        guard let url = URL(string: mailtoString) else { return }
        UIApplication.shared.open(url)
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
}


struct ContactRowCard<MenuContent: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let action: () -> Void
    let hasMenu: Bool
    let menuContent: () -> MenuContent

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 30)

                // Contact info
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Menu for additional options
                if hasMenu {
                    Menu {
                        menuContent()
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RepresentativeDetailView(contact: Contact.housePreviewContact)
}