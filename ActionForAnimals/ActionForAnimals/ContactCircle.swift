//
//  ContactCircle.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 8/3/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import SwiftUI

struct ContactCircle: View {
    @EnvironmentObject var store: Store
    
    let issueID: Int?
    let contact: Contact
    
    init(contact: Contact, issueID: Int? = nil) {
        self.contact = contact
        self.issueID = issueID
    }
    
    var body: some View {
        GeometryReader { geo in
            let showComplete = issueID.flatMap {
                store.state.issueCalledOn(issueID: $0, contactID: contact.id)
            } ?? false
            let size = min(geo.size.width, geo.size.height)

            Group {
                if let url = contact.photoURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipped()
                    } placeholder: { placeholder }
                } else {
                    placeholder
                }
            }
            .clipShape(Circle())
            .completionCheckmarkOverlay(show: showComplete, containerSize: size, mode: .replace)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    var placeholder: some View {
        Image(uiImage: defaultImage(forContact: contact))
            .resizable()
            .mask {
                Circle()
            }
    }
}

#Preview {
    let storeWithCompletedIssues: Store = {
        let state = AppState()
        state.issueCompletion[123] = [ContactLog(issueId: "123", contactId: "1234", phone: "", outcome: "contact", date: Date(), reported: true, actionType: "call")]
        return Store(state: state)
    }()
    
    return HStack {
        ContactCircle(contact: Contact.housePreviewContact)
            .frame(width: 40, height: 40)
        ContactCircle(contact: Contact.housePreviewContact, issueID: 123)
            .frame(width: 40, height: 40)
            .environmentObject(storeWithCompletedIssues)
        ContactCircle(contact: Contact.senatePreviewContact1)
            .frame(width: 40)
        ContactCircle(contact: Contact.weirdShapeImagePreviewContact)
            .frame(width: 40, height: 40)
        Circle()
            .frame(width: 40, height: 40)
    }
}
