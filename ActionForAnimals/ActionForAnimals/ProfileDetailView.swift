//
//  ProfileDetailView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

struct ProfileDetailView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var showAvatarSelection = false
    @State private var showNameEdit = false
    @State private var showEmailEdit = false
    @Environment(\.dismiss) private var dismiss

    let showDoneButton: Bool

    init(showDoneButton: Bool = false) {
        self.showDoneButton = showDoneButton
    }

    var body: some View {
        List {
            // Avatar section
            Section {
                VStack(spacing: 16) {
                    // Large circular avatar
                    Image(profileManager.currentProfile.avatarIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                        .clipShape(Circle())

                    // Edit Photo button
                    Button("Edit Photo") {
                        showAvatarSelection = true
                    }
                    .foregroundColor(.teal)
                    .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)

            // Name section
            Section {
                Button(action: {
                    showNameEdit = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileManager.currentProfile.displayName)
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(profileManager.currentProfile.displayNickname)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("Name")
            }

            // Email section
            Section {
                Button(action: {
                    showEmailEdit = true
                }) {
                    HStack {
                        Text(profileManager.currentProfile.displayEmail)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("Email")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible)
        .toolbarBackground(Color.afaDarkBlue)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if showDoneButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showAvatarSelection) {
            AvatarSelectionView(userProfile: $profileManager.currentProfile)
        }
        .sheet(isPresented: $showNameEdit) {
            NameEditView(userProfile: $profileManager.currentProfile)
        }
        .sheet(isPresented: $showEmailEdit) {
            EmailEditView(userProfile: $profileManager.currentProfile)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
}