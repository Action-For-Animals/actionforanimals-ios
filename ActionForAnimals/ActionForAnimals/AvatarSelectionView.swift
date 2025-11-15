//
//  AvatarSelectionView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

struct AvatarSelectionView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedAvatar: String

    init(userProfile: Binding<UserProfile>) {
        // Initialize with current profile avatar
        self._selectedAvatar = State(initialValue: ProfileManager.shared.currentProfile.avatarIconName)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Large preview of selected avatar
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(selectedAvatar)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                }

                // Avatar selection grid
                VStack(spacing: 20) {
                    Text("Select an Avatar")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(UserProfile.availableAvatars, id: \.self) { avatar in
                            AvatarOptionView(
                                iconName: avatar,
                                isSelected: selectedAvatar == avatar
                            ) {
                                selectedAvatar = avatar
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
            .navigationTitle("Choose Avatar")
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
                        profileManager.updateAvatar(selectedAvatar)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct AvatarOptionView: View {
    let iconName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)

                    if isSelected {
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 80, height: 80)
                    }
                }

                Text(UserProfile.avatarDisplayName(for: iconName))
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AvatarSelectionView(userProfile: .constant(UserProfile(avatar: "badge-wildlife")))
}