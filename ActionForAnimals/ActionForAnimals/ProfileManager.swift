//
//  ProfileManager.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import Foundation
import Combine

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var currentProfile: UserProfile {
        didSet {
            saveProfile()
        }
    }

    private init() {
        self.currentProfile = Self.loadProfile()
    }

    private static func loadProfile() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: "UserProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile() // Return empty profile if none exists
        }
        return profile
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(currentProfile) {
            UserDefaults.standard.set(data, forKey: "UserProfile")
        }

        // Also save to backend
        saveToBackend(profile: currentProfile)
    }

    func updateProfile(_ updatedProfile: UserProfile) {
        currentProfile = updatedProfile
    }

    func updateAvatar(_ avatar: String) {
        currentProfile.avatar = avatar
    }

    func updateName(firstName: String?, lastName: String?) {
        currentProfile.firstName = firstName
        currentProfile.lastName = lastName
    }

    func updateNickname(_ nickname: String?) {
        currentProfile.nickname = nickname
    }

    func updateEmail(_ email: String?) {
        currentProfile.email = email
    }

    func clearProfile() {
        currentProfile = UserProfile()
        UserDefaults.standard.removeObject(forKey: "UserProfile")
    }

    func saveToBackend(profile: UserProfile) {
        let operation = SaveUserInfoOperation(userProfile: profile)
        let queue = OperationQueue()
        queue.addOperation(operation)
    }
}