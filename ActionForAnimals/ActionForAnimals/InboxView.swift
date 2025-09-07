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
    @State private var showContactAlert: Bool = false

    var contacts: [Contact] {
        return store.state.contacts.filter({ $0.area == "US House" || $0.area == "US Senate" })
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
                    HStack {
                        Text(R.string.localizable.inboxRepsHeader())
                            .font(.body)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        ForEach(contacts.numbered()) { contact in
                            ContactListItem(contact: contact.element, showComplete: false)
                                .onTapGesture {
                                    showContactAlert = true
                                }
                        }
                        
                        ForEach(store.state.missingReps, id: \.self) { missingRepArea in
                            ContactListItem(contact: Contact(name: R.string.localizable.vacantSeatTitle()), contactNote: R.string.localizable.vacantSeatMessage(missingRepArea))
                                .opacity(0.5)
                        }
                    }
                }.padding(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }.alert(R.string.localizable.inboxContactAlert(), isPresented: $showContactAlert) {
            Button(R.string.localizable.okButtonTitle(), role: .cancel) { }
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
