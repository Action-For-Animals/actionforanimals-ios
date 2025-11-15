//
//  ProfileCardView.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import SwiftUI

struct ProfileCardView: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            // Circular avatar on the left
            Image(profile.avatarIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.gray.opacity(0.1)))
                .clipShape(Circle())

            // Name and nickname in the middle
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(profile.displayNickname)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        Section {
            ProfileCardView(profile: UserProfile(
                firstName: "John",
                lastName: "Doe",
                nickname: "Animal Lover",
                email: "john@example.com",
                avatar: "badge-wildlife"
            ))
        }
    }
}