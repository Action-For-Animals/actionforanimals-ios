//
//  AppState.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 7/24/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import Foundation
import CoreLocation
import os

class AppState: ObservableObject, ReduxState {
    @Published var showWelcomeScreen = false
    @Published var showYourImpact = false
    @Published var selectedTab = "topics"
    @Published var globalCallCount: Int = 0
    @Published var issueCallCounts: [Int: Int] = [:]
    @Published var weeklyStreak: Int = 0 {
        didSet {
            UserDefaults.standard.set(weeklyStreak, forKey: UserDefaultsKey.weeklyStreak.rawValue)
        }
    }
    @Published var lastActionWeek: String? = nil { // Store as "YYYY-ww" format
        didSet {
            if let week = lastActionWeek {
                UserDefaults.standard.set(week, forKey: UserDefaultsKey.lastActionWeek.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.lastActionWeek.rawValue)
            }
        }
    }
    // issueCompletion is a local cache of completed calls: an array of contact id and outcomes (B0001234-contact) keyed by an issue id
    @Published var issueCompletion: [Int: [ContactLog]] = [:] {
        didSet {
            // Serialize ContactLog objects to Data for storage
            do {
                let encoder = JSONEncoder()
                let plistSupportableIssueCache: [String: Data] = Dictionary(uniqueKeysWithValues: issueCompletion.compactMap { key, value in
                    guard let data = try? encoder.encode(value) else { return nil }
                    return (String(key), data)
                })
                UserDefaults.standard.set(plistSupportableIssueCache, forKey: UserDefaultsKey.issueCompletionCache.rawValue)
            }
        }
    }
    @Published var donateOn = false
    @Published var issues: [AnimalPolicy] = []
    @Published var issueFetchTime: Date? = nil
    // Cache of last known issues for change detection across app sessions
    var lastKnownIssues: [AnimalPolicy] = []
    @Published var contacts: [Contact] = []
    @Published var district: String? = nil
    @Published var isSplitDistrict: Bool = false
    @Published var lowAccuracyMessage: String? = nil
    @Published var missingReps: [String] = []
    @Published var location: UserLocation? {
        didSet {
            guard let location = self.location else { return }
            let defaults = UserDefaults.standard
            defaults.set(location.locationType.rawValue, forKey: UserDefaultsKey.locationType.rawValue)
            defaults.set(location.locationValue, forKey: UserDefaultsKey.locationValue.rawValue)
            defaults.set(location.locationDisplay, forKey: UserDefaultsKey.locationDisplay.rawValue)
            Logger().info("saved cached location as \(location)")
        }
    }

    // Location metadata from getOfficials API for campaign filtering
    @Published var city: String? {  // from ContactList.location
        didSet {
            let defaults = UserDefaults.standard
            if let city = city {
                defaults.set(city, forKey: UserDefaultsKey.locationCity.rawValue)
            } else {
                defaults.removeObject(forKey: UserDefaultsKey.locationCity.rawValue)
            }
        }
    }
    @Published var county: String? { // from ContactList.county
        didSet {
            let defaults = UserDefaults.standard
            if let county = county {
                defaults.set(county, forKey: UserDefaultsKey.locationCounty.rawValue)
            } else {
                defaults.removeObject(forKey: UserDefaultsKey.locationCounty.rawValue)
            }
        }
    }
    @Published var state: String? {  // from ContactList.state
        didSet {
            let defaults = UserDefaults.standard
            if let state = state {
                defaults.set(state, forKey: UserDefaultsKey.locationState.rawValue)
            } else {
                defaults.removeObject(forKey: UserDefaultsKey.locationState.rawValue)
            }
        }
    }
    @Published var selectedCategoryFilter: String? {
        didSet {
            if let filter = selectedCategoryFilter {
                UserDefaults.standard.set(filter, forKey: UserDefaultsKey.selectedCategoryFilter.rawValue)
                Logger().info("saved category filter: \(filter)")
            }
        }
    }
    @Published var fetchingContacts = false
    // if we don't have any loaded messages, this is set to a message id we expect to receive for immediate navigation,
    // i.e. we've tapped on a push notification about a message
    var wantedMessageID: Int?
    // TODO: display this error on welcome screen and anywhere else that uses stats
    @Published var statsLoadingError: Error? = nil
    // TODO: display this error on the dashboard issue list (and the More page when it exists)
    @Published var issueLoadingError: Error? = nil
    // TODO: display this error on the dashboard (and location sheet?)
    @Published var contactsLoadingError: Error? = nil
    
    @Published var issueRouter: AnimalPolicyRouter = AnimalPolicyRouter()
    
    @Published var changedCampaignIds: Set<Int> = [] {
        didSet {
            // Persist to UserDefaults
            UserDefaults.standard.set(Array(changedCampaignIds), forKey: "changedCampaignIds")
        }
    }
    
    init() {
        // load user location cache
        if let locationType = UserDefaults.standard.string(forKey: UserDefaultsKey.locationType.rawValue),
            let locationValue = UserDefaults.standard.string(forKey: UserDefaultsKey.locationValue.rawValue) {
            let locationDisplay = UserDefaults.standard.string(forKey: UserDefaultsKey.locationDisplay.rawValue)
            Logger().info("loading cached location: \(locationType) \(locationValue) \(locationDisplay ?? "")")
            
            switch locationType {
            case "address", "zipCode":
                self.location = UserLocation(address: locationValue, display: locationDisplay)
            case "coordinates":
                let locValues = locationValue.split(separator: ",")
                if locValues.count != 2 { return }
                guard let lat = Double(locValues[0]), let lng = Double(locValues[1]) else { return }
                
                self.location = UserLocation(location: CLLocation(latitude: lat, longitude: lng), display: locationDisplay)
            default:
                Logger().warning("unknown stored location type data: \(locationType)")
            }
        }

        // load cached location metadata
        self.city = UserDefaults.standard.string(forKey: UserDefaultsKey.locationCity.rawValue)
        self.county = UserDefaults.standard.string(forKey: UserDefaultsKey.locationCounty.rawValue)
        self.state = UserDefaults.standard.string(forKey: UserDefaultsKey.locationState.rawValue)

        // load the issue completion cache
        if let plistSupportableIssueCache = UserDefaults.standard.object(forKey: UserDefaultsKey.issueCompletionCache.rawValue) as? [String: Data] {
            let decoder = JSONDecoder()
            self.issueCompletion = Dictionary(uniqueKeysWithValues: plistSupportableIssueCache.compactMap({ key, data in
                guard let intKey = Int(key),
                      let contactLogs = try? decoder.decode([ContactLog].self, from: data) else {
                    return nil
                }
                return (intKey, contactLogs)
            }))
        }
        
        // load category filter preference
        self.selectedCategoryFilter = UserDefaults.standard.string(forKey: UserDefaultsKey.selectedCategoryFilter.rawValue)
        if let filter = selectedCategoryFilter {
            Logger().info("loading cached category filter: \(filter)")
        }
        
        // load persisted changed campaign IDs
        if let savedIds = UserDefaults.standard.array(forKey: "changedCampaignIds") as? [Int] {
            self.changedCampaignIds = Set(savedIds)
        }

        // load weekly streak data
        self.weeklyStreak = UserDefaults.standard.integer(forKey: UserDefaultsKey.weeklyStreak.rawValue)
        self.lastActionWeek = UserDefaults.standard.string(forKey: UserDefaultsKey.lastActionWeek.rawValue)

        // Initialize weekly streak for app upgrades
        let hasSeenImpactCounter = UserDefaults.standard.bool(forKey: "hasSeenImpactCounter")
        if !hasSeenImpactCounter && self.weeklyStreak == 0 && self.lastActionWeek == nil {
            // This is likely an app upgrade - check for actions this week
            let completionLogs = self.issueCompletion.values.flatMap { $0 }

            var calendar = Calendar.current
            calendar.firstWeekday = 2 // Monday = 2
            let now = Date()
            let currentWeekString = String(format: "%04d-%02d",
                                         calendar.component(.yearForWeekOfYear, from: now),
                                         calendar.component(.weekOfYear, from: now))

            let thisWeekLogs = completionLogs.filter { log in
                let logYear = calendar.component(.yearForWeekOfYear, from: log.date)
                let logWeek = calendar.component(.weekOfYear, from: log.date)
                let logWeekString = String(format: "%04d-%02d", logYear, logWeek)
                return logWeekString == currentWeekString
            }

            if !thisWeekLogs.isEmpty {
                // User has actions this week - set initial streak
                self.weeklyStreak = 1
                self.lastActionWeek = currentWeekString
                UserDefaults.standard.set(1, forKey: UserDefaultsKey.weeklyStreak.rawValue)
                UserDefaults.standard.set(currentWeekString, forKey: UserDefaultsKey.lastActionWeek.rawValue)
            }
        }

        // load cached issues for change detection
        if let cachedIssuesData = UserDefaults.standard.data(forKey: "lastKnownIssues") {
            let decoder = JSONDecoder()
            if let cachedIssues = try? decoder.decode([AnimalPolicy].self, from: cachedIssuesData) {
                self.lastKnownIssues = cachedIssues
            }
        }
    }
}

extension AppState {
    func issueCalledOn(issueID: Int, contactID: String) -> Bool {
        let contactLogsForIssue = self.issueCompletion[issueID] ?? []
        return contactLogsForIssue.contains { $0.contactId == contactID }
    }
    
    var needsIssueRefresh: Bool {
        guard let issueFetchTime else {
            return true
        }

        if issueFetchTime < Date().addingTimeInterval(-1 * 60) {
            return true
        } else {
            return false
        }
    }
    
    /// Get the user's selected category filters as a Set
    var selectedCategoryFilters: Set<String> {
        guard let filterString = selectedCategoryFilter, !filterString.isEmpty else {
            return ["all"]
        }
        return Set(filterString.split(separator: ",").map { String($0) })
    }
    
    /// Check if the user is interested in a specific category
    func isInterestedInCategory(_ category: String) -> Bool {
        let filters = selectedCategoryFilters
        return filters.contains("all") || filters.contains(category)
    }
}
