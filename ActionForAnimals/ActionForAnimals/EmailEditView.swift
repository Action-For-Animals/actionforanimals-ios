//
//  EmailEditView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

struct EmailEditView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var email: String

    private var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return email.isEmpty || (emailPredicate.evaluate(with: email) && email.count <= 254)
    }

    private var canSave: Bool {
        return email.isEmpty || isValidEmail
    }

    init(userProfile: Binding<UserProfile>) {
        self._email = State(initialValue: ProfileManager.shared.currentProfile.email ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Email Address", text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: email) { newValue in
                            if newValue.count > 254 {
                                email = String(newValue.prefix(254))
                            }
                        }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if !email.isEmpty && !isValidEmail {
                            Text("Please enter a valid email address.")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        Text("Your email address will be kept private and used only for account purposes.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Email")
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
                        profileManager.updateEmail(email.isEmpty ? nil : email)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    EmailEditView(userProfile: .constant(UserProfile(email: "john@example.com")))
}