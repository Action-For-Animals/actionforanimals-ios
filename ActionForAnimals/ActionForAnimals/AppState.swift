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
    @Published var animalsHelpedThisMonth: Int = 0 {
        didSet {
            UserDefaults.standard.set(animalsHelpedThisMonth, forKey: UserDefaultsKey.animalsHelpedThisMonth.rawValue)
        }
    }
    @Published var lastMonthlyCountUpdate: String? = nil { // Store as "YYYY-MM" format
        didSet {
            if let month = lastMonthlyCountUpdate {
                UserDefaults.standard.set(month, forKey: UserDefaultsKey.lastMonthlyCountUpdate.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.lastMonthlyCountUpdate.rawValue)
            }
        }
    }
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

    // Monthly challenge current leaderboard caching
    @Published var cachedCurrentLeaderboard: [LeagueParticipant] = []
    @Published var cachedCurrentMeta: LeagueMeta?
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

    // Deadline value recorded at the moment a campaign was fully completed - used to
    // detect whether the deadline has changed since, so a finished campaign can bubble
    // back up if there's a genuine new ask rather than a routine content edit.
    @Published var completedCampaignDeadlines: [Int: Date] = [:] {
        didSet {
            let plistSupportable = Dictionary(uniqueKeysWithValues: completedCampaignDeadlines.map { (String($0.key), $0.value) })
            UserDefaults.standard.set(plistSupportable, forKey: UserDefaultsKey.completedCampaignDeadlines.rawValue)
        }
    }

    // Date the user last fully completed a campaign - only ContactLog entries dated after
    // this count toward satisfying a fresh round, so stale logs from a previous round
    // (before a deadline changed) can't cover for a contact that hasn't been redone.
    @Published var lastFullCompletionDate: [Int: Date] = [:] {
        didSet {
            let plistSupportable = Dictionary(uniqueKeysWithValues: lastFullCompletionDate.map { (String($0.key), $0.value) })
            UserDefaults.standard.set(plistSupportable, forKey: UserDefaultsKey.lastFullCompletionDate.rawValue)
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

        // load persisted completed-campaign deadline snapshots
        if let savedDeadlines = UserDefaults.standard.dictionary(forKey: UserDefaultsKey.completedCampaignDeadlines.rawValue) as? [String: Date] {
            self.completedCampaignDeadlines = Dictionary(uniqueKeysWithValues: savedDeadlines.compactMap { key, value in
                guard let intKey = Int(key) else { return nil }
                return (intKey, value)
            })
        }

        // load persisted last-full-completion dates
        if let savedDates = UserDefaults.standard.dictionary(forKey: UserDefaultsKey.lastFullCompletionDate.rawValue) as? [String: Date] {
            self.lastFullCompletionDate = Dictionary(uniqueKeysWithValues: savedDates.compactMap { key, value in
                guard let intKey = Int(key) else { return nil }
                return (intKey, value)
            })
        }

        // load weekly streak data
        self.weeklyStreak = UserDefaults.standard.integer(forKey: UserDefaultsKey.weeklyStreak.rawValue)
        self.lastActionWeek = UserDefaults.standard.string(forKey: UserDefaultsKey.lastActionWeek.rawValue)

        // load monthly animals helped data with reset check
        self.animalsHelpedThisMonth = UserDefaults.standard.integer(forKey: UserDefaultsKey.animalsHelpedThisMonth.rawValue)
        self.lastMonthlyCountUpdate = UserDefaults.standard.string(forKey: UserDefaultsKey.lastMonthlyCountUpdate.rawValue)

        // Check if we need to reset monthly counter
        checkAndResetMonthlyCounter()

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

        // load cached issues for change detection AND immediate display
        if let cachedIssuesData = UserDefaults.standard.data(forKey: "lastKnownIssues") {
            let decoder = JSONDecoder()
            if let cachedIssues = try? decoder.decode([AnimalPolicy].self, from: cachedIssuesData) {
                self.lastKnownIssues = cachedIssues
                self.issues = cachedIssues // Show cached data immediately
                print("📰 [AppState.init] Loaded \(cachedIssues.count) cached issues")
                // Don't set issueFetchTime - we still want the 1-minute refresh check
            } else {
                print("❌ [AppState.init] Failed to decode cached issues")
            }
        } else {
            print("📰 [AppState.init] No cached issues found")
        }

        // load cached contacts for immediate display (representatives change less frequently)
        if let cachedContactsData = UserDefaults.standard.data(forKey: "cachedContacts") {
            let decoder = JSONDecoder()
            if let cachedContacts = try? decoder.decode([Contact].self, from: cachedContactsData) {
                self.contacts = cachedContacts
                print("📋 [AppState.init] Loaded \(cachedContacts.count) cached contacts")

                // Log cache age
                if let cacheTime = UserDefaults.standard.object(forKey: "contactsFetchTime") as? Date {
                    let ageSeconds = Date().timeIntervalSince(cacheTime)
                    if ageSeconds < 3600 { // Less than 1 hour
                        let ageMinutes = ageSeconds / 60
                        print("📋 [AppState.init] Contacts cache age: \(String(format: "%.1f", ageMinutes)) minutes")
                    } else {
                        let ageHours = ageSeconds / 3600
                        print("📋 [AppState.init] Contacts cache age: \(String(format: "%.1f", ageHours)) hours")
                    }
                }
                // Don't set contactsFetchTime - we'll check cache expiration in needsContactRefresh
            } else {
                print("❌ [AppState.init] Failed to decode cached contacts")
            }
        } else {
            print("📋 [AppState.init] No cached contacts found")
        }

        // Backfill lastFullCompletionDate (and completedCampaignDeadlines where applicable)
        // for any already-fully-completed campaign that doesn't have an entry yet.
        // needsAction(issue:) gates purely on lastFullCompletionDate being set, so without
        // this, every pre-existing completed campaign would look like it still needs
        // action. Checked per-campaign rather than gated on the whole map being empty, so
        // this safely runs every launch and picks up anything missed - including campaigns
        // completed in older sessions before this feature existed.
        for issue in lastKnownIssues {
            guard lastFullCompletionDate[issue.id] == nil, isFullyCompleted(issue: issue) else { continue }
            if let deadline = issue.deadline {
                completedCampaignDeadlines[issue.id] = deadline
            }
            if let mostRecent = (issueCompletion[issue.id] ?? []).map(\.date).max() {
                lastFullCompletionDate[issue.id] = mostRecent
            }
        }
    }
}

extension AppState {
    func issueCalledOn(issueID: Int, contactID: String) -> Bool {
        let contactLogsForIssue = self.issueCompletion[issueID] ?? []
        return contactLogsForIssue.contains { $0.contactId == contactID }
    }

    enum ContactCompletionState: Equatable {
        case contactedThisRound
        case needsRedo
        case neverContacted
    }

    // Round-aware version of issueCalledOn, for UI that needs to distinguish "done this
    // round" from "done before, but not since the campaign's last full completion" -
    // e.g. list-row contact circles, which sit right next to a badge/position that
    // signals whether the campaign currently needs fresh action.
    func contactCompletionState(issueID: Int, contactID: String) -> ContactCompletionState {
        let mostRecent = (issueCompletion[issueID] ?? [])
            .filter { $0.contactId == contactID }
            .map(\.date)
            .max()

        guard let mostRecent else { return .neverContacted }

        // Only apply the cutoff distinction while the campaign actually needs action
        // (i.e. it's mid-bubble-up after a deadline change). lastFullCompletionDate is
        // always recorded slightly after the completions that triggered it, so if the
        // campaign is already settled, every one of its own completions would otherwise
        // look like it's "before the cutoff" - there's no round to distinguish once
        // nothing has changed, so just show it as done.
        if let issue = issues.first(where: { $0.id == issueID }), !needsAction(issue: issue) {
            return .contactedThisRound
        }

        if let cutoff = lastFullCompletionDate[issueID], mostRecent <= cutoff {
            return .needsRedo
        }
        return .contactedThisRound
    }

    // Has the user completed every contact (political) or target (corporate) required
    // for this campaign? Batch email corporate campaigns only need a single completion.
    // Only counts ContactLog entries dated after the last time this campaign was fully
    // completed, so a stale log from a previous round (before a deadline changed) can't
    // cover for a contact that hasn't actually been redone this round.
    func isFullyCompleted(issue: AnimalPolicy) -> Bool {
        isFullyCompleted(issue: issue, completions: issueCompletion[issue.id] ?? [])
    }

    // Same check, but takes an explicit completions list rather than reading
    // issueCompletion directly - needed because Store.dispatch() defers its reducer
    // mutation via DispatchQueue.main.async, so state read back immediately after a
    // dispatch() call can be one action stale. Callers that just dispatched a new
    // ContactLog should pass the up-to-date list themselves.
    func isFullyCompleted(issue: AnimalPolicy, completions allCompletions: [ContactLog]) -> Bool {
        guard !allCompletions.isEmpty else { return false }

        let completions: [ContactLog]
        if let cutoff = lastFullCompletionDate[issue.id] {
            completions = allCompletions.filter { $0.date > cutoff }
        } else {
            completions = allCompletions
        }
        guard !completions.isEmpty else { return false }

        if issue.contactType == .corporate {
            guard let targets = issue.targets, !targets.isEmpty else { return false }
            if issue.isBatchEmailCampaign {
                return targets.contains { target in completions.contains { $0.contactId == target.id } }
            }
            return targets.allSatisfy { target in completions.contains { $0.contactId == target.id } }
        } else {
            let relevantContacts = issue.contactsForIssue(allContacts: contacts)
            guard !relevantContacts.isEmpty else { return false }
            return relevantContacts.allSatisfy { contact in completions.contains { $0.contactId == contact.id } }
        }
    }

    // True if this campaign still needs the user's attention: either it has never been
    // fully completed, or it was completed but the deadline has changed since then.
    // Deliberately does NOT re-run the live, cutoff-filtered isFullyCompleted(issue:) check
    // here - that check's cutoff is set at the moment of completion, so it would exclude
    // the very completions that just satisfied it on every subsequent call. Once a
    // completion is durably recorded (lastFullCompletionDate is set), that fact alone
    // is what settles it, not a live re-derivation.
    func needsAction(issue: AnimalPolicy) -> Bool {
        guard lastFullCompletionDate[issue.id] != nil else { return true }
        return issue.deadline != completedCampaignDeadlines[issue.id]
    }

    func checkAndResetMonthlyCounter() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = String(format: "%04d-%02d",
                                calendar.component(.year, from: now),
                                calendar.component(.month, from: now))

        // If we don't have a stored month or it's different from current month, reset
        if lastMonthlyCountUpdate == nil || lastMonthlyCountUpdate != currentMonth {
            // Reset monthly counter
            animalsHelpedThisMonth = 0
            lastMonthlyCountUpdate = currentMonth

            Logger().info("Monthly counter reset for new month: \(currentMonth)")
        }
    }

    var needsContactsRefresh: Bool {
        // Check if cached contacts are stale (7 days - representatives change very infrequently)
        if let contactsFetchTime = UserDefaults.standard.object(forKey: "contactsFetchTime") as? Date {
            return contactsFetchTime < Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days
        }
        return true // No cache time means we need to fetch
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
