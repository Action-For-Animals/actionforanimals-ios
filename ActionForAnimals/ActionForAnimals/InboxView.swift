//
//  InboxView.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 2/25/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import SwiftUI

struct InboxView: View {
    @EnvironmentObject var store: Store
    @State private var selectedContact: Contact?

    // Group contacts by role - legislators first, then other officials
    var federalLegislators: [Contact] {
        return store.state.contacts.filter({ $0.area == "US House" || $0.area == "US Senate" })
    }

    var stateLegislators: [Contact] {
        return store.state.contacts.filter({
            $0.area == "Governor" ||
            $0.area == "StateLower" ||
            $0.area == "StateUpper" ||
            $0.area == "State Assembly" ||
            $0.area == "State Senate"
        })
    }

    var localLegislators: [Contact] {
        return store.state.contacts.filter({
            $0.area == "Mayor" ||
            $0.area == "City Council" ||
            $0.area == "County Supervisor" ||
            $0.area.contains("Council") ||
            $0.area.contains("Supervisor")
        })
    }

    var otherOfficials: [Contact] {
        let allLegislators = federalLegislators + stateLegislators + localLegislators
        return store.state.contacts.filter({ !allLegislators.contains($0) })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MainHeader()
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            if store.state.contacts.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrowshape.up.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 4)
                        Text(R.string.localizable.inboxEmptyState())
                            .font(.title2)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }.accessibilityElement(children: .combine)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // Local Legislators Section
                        if !localLegislators.isEmpty {
                            RepresentativeSection(
                                title: "Local Legislators",
                                contacts: localLegislators,
                                selectedContact: $selectedContact
                            )
                        }

                        // State Legislators Section
                        if !stateLegislators.isEmpty {
                            RepresentativeSection(
                                title: "State Legislators",
                                contacts: stateLegislators,
                                selectedContact: $selectedContact
                            )
                        }

                        // Federal Legislators Section
                        if !federalLegislators.isEmpty {
                            RepresentativeSection(
                                title: "Federal Legislators",
                                contacts: federalLegislators,
                                selectedContact: $selectedContact
                            )
                        }


                        // Vacant/Missing Representatives
                        if !store.state.missingReps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vacant Positions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .accessibilityAddTraits(.isHeader)

                                VStack(spacing: 0) {
                                    ForEach(store.state.missingReps, id: \.self) { missingRepArea in
                                        ContactListItem(
                                            contact: Contact(name: R.string.localizable.vacantSeatTitle()),
                                            contactNote: R.string.localizable.vacantSeatMessage(missingRepArea)
                                        )
                                        .opacity(0.5)
                                    }
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(Color.afaLightBG)
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
        .sheet(item: $selectedContact) { contact in
            RepresentativeDetailView(contact: contact)
        }
    }
}

// MARK: - Representative Section Component
struct RepresentativeSection: View {
    let title: String
    let contacts: [Contact]
    @Binding var selectedContact: Contact?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(contacts.numbered()) { contact in
                    ContactListItem(contact: contact.element, showComplete: false)
                        .onTapGesture {
                            selectedContact = contact.element
                        }

                    if contact.number < contacts.count - 1 {
                        Divider()
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color.afaLightBG)
            }
        }
    }
}

#Preview {
    let previewState = {
        let state = AppState()
        state.contacts = [
            Contact.housePreviewContact,
            Contact.senatePreviewContact1,
            Contact.senatePreviewContact2
        ]
        return state
    }()

    let store = Store(state: previewState, middlewares: [appMiddleware()])

    return InboxView().environmentObject(store)
}
