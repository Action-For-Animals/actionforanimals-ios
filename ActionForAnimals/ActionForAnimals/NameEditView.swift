//
//  NameEditView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

struct NameEditView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var nickname: String

    init(userProfile: Binding<UserProfile>) {
        let currentProfile = ProfileManager.shared.currentProfile
        self._firstName = State(initialValue: currentProfile.firstName ?? "")
        self._lastName = State(initialValue: currentProfile.lastName ?? "")
        self._nickname = State(initialValue: currentProfile.nickname ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: firstName) { newValue in
                            if newValue.count > 50 {
                                firstName = String(newValue.prefix(50))
                            }
                        }

                    TextField("Last Name (Optional)", text: $lastName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: lastName) { newValue in
                            if newValue.count > 50 {
                                lastName = String(newValue.prefix(50))
                            }
                        }
                } footer: {
                    Text("Your name will be automatically inserted into campaign scripts and emails.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section {
                    TextField("Nickname", text: $nickname)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: nickname) { newValue in
                            if newValue.count > 30 {
                                nickname = String(newValue.prefix(30))
                            }
                        }
                } footer: {
                    Text("Nickname will be displayed in monthly challenges.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible)
            .toolbarBackground(Color.afaDarkBlue)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profileManager.updateName(
                            firstName: firstName.isEmpty ? nil : firstName,
                            lastName: lastName.isEmpty ? nil : lastName
                        )
                        profileManager.updateNickname(nickname.isEmpty ? nil : nickname)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NameEditView(userProfile: .constant(UserProfile(
        firstName: "John",
        lastName: "Doe",
        nickname: "Animal Lover"
    )))
}