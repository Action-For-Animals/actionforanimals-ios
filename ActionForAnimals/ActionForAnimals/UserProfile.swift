//
//  UserProfile.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import Foundation

struct UserProfile: Codable {
    var firstName: String?
    var lastName: String?
    var nickname: String?
    var email: String?
    var avatar: String? // badge icon name (e.g., "badge-wildlife")

    var displayName: String {
        if let firstName = firstName, !firstName.isEmpty {
            if let lastName = lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return "Add Name"
    }

    var displayNickname: String {
        return nickname?.isEmpty == false ? nickname! : "Add Nickname"
    }

    var displayEmail: String {
        return email?.isEmpty == false ? email! : "Add Email"
    }

    var avatarIconName: String {
        return avatar ?? "chicken_avatar" // default to chicken avatar
    }

    init() {
        // Default empty profile
    }

    init(firstName: String? = nil, lastName: String? = nil, nickname: String? = nil, email: String? = nil, avatar: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.nickname = nickname
        self.email = email
        self.avatar = avatar
    }
}

// MARK: - UserDefaults Persistence (Legacy - use ProfileManager instead)
extension UserProfile {
    private static let userDefaultsKey = "UserProfile"

    static func load() -> UserProfile {
        // Delegate to ProfileManager
        return ProfileManager.shared.currentProfile
    }

    func save() {
        // Delegate to ProfileManager
        ProfileManager.shared.updateProfile(self)
    }

    static func clear() {
        ProfileManager.shared.clearProfile()
    }
}

// MARK: - Available Avatars
extension UserProfile {
    static let availableAvatars = [
        "lion_avatar",
        "cow_avatar",
        "dog_avatar",
        "cat_avatar",
        "dolphin_avatar",
        "chicken_avatar",
        "fox_avatar",
        "rabbit_avatar",
        "turtle_avatar"
    ]

    static func avatarDisplayName(for iconName: String) -> String {
        switch iconName {
        case "lion_avatar": return "Lion"
        case "cow_avatar": return "Cow"
        case "dog_avatar": return "Dog"
        case "cat_avatar": return "Cat"
        case "dolphin_avatar": return "Dolphin"
        case "chicken_avatar": return "Chicken"
        case "fox_avatar": return "Fox"
        case "rabbit_avatar": return "Rabbit"
        case "turtle_avatar": return "Turtle"
        default: return "Unknown"
        }
    }
}