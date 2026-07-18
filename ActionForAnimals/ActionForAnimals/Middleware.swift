//
 //  Middlewares.swift
 //  ActionForAnimals
 //
 //  Created by Christopher Selin on 9/22/23.
 //  Copyright © 2023 5calls. All rights reserved.
 //
 import Foundation
 import UserNotifications

let streakRiskNotificationIdentifier = "actionforanimals-streak-risk"

func appMiddleware() -> Middleware<AppState> {
    return { state, action, dispatch in
        switch action {
        case let .FetchStats(issueID):
            fetchStats(issueID: issueID, dispatch: dispatch)
        case .FetchIssues:
            fetchIssues(state: state, dispatch: dispatch)
        case .FetchCurrentLeaderboard:
            fetchCurrentLeaderboard(dispatch: dispatch)
        case let .FetchContacts(location):
            fetchContacts(location: location, state: state, dispatch: dispatch)
        case let .SetLocation(location):
            // Always show loading for location changes (getting new representatives)
            dispatch(.SetFetchingContacts(true))
            fetchContacts(location: location, state: state, dispatch: dispatch)
        case let .ReportOutcome(issue, contactLog, outcome):
            // TODO: migrate ContactLog issueId to Int after UIKit is gone
            // this is always generated in swiftUI from an int so it should always succeed
            if let issueId = Int(contactLog.issueId) {
                // Only track completion for non-skip outcomes
                if outcome.status != "skip" {
                    dispatch(.SetIssueContactCompletion(issueId, contactLog))
                    dispatch(.TrackImpact(contactLog, issue))

                    // Increment monthly animals counter
                    let animalsHelped = contactLog.animalsHelped ?? 1
                    dispatch(.IncrementMonthlyAnimals(animalsHelped))

                    // Keep the completion-time deadline snapshot in sync whenever the
                    // campaign is (still) fully completed after this action. Build the
                    // up-to-date completions list explicitly rather than reading
                    // state.issueCompletion back, since dispatch()'s reducer mutation is
                    // deferred (DispatchQueue.main.async) and wouldn't reflect this log yet.
                    let updatedCompletions = (state.issueCompletion[issueId] ?? []) + [contactLog]
                    if state.isFullyCompleted(issue: issue, completions: updatedCompletions) {
                        dispatch(.RecordCampaignCompletionDeadline(issue.id, issue.deadline))
                    }
                }
            }
            AnalyticsManager.shared.trackEvent(name: "Outcome-\(outcome.status)", path: "/issue/\(issue.slug)/")

            // Only report outcome to server if it's not a skip - skips should not update counts
            if outcome.status != "skip" {
                // Calculate updated count to send to server (current count + this action)
                let animalsHelped = contactLog.animalsHelped ?? 1
                let updatedMonthlyCount = state.animalsHelpedThisMonth + animalsHelped
                reportOutcome(log: contactLog, outcome: outcome, dispatch: dispatch, updatedCount: updatedMonthlyCount)

                // Compute the resulting streak directly rather than reading state back
                // after dispatch(), since dispatch()'s reducer mutation is deferred via
                // DispatchQueue.main.async and wouldn't reflect this action's update yet.
                let (resultingStreak, _) = computeNextWeeklyStreak(currentStreak: state.weeklyStreak, lastActionWeek: state.lastActionWeek)
                dispatch(.UpdateWeeklyStreak)
                scheduleStreakRiskReminder(currentStreak: resultingStreak)

                // Refresh leaderboard cache only if user is in current month's league
                if isUserInCurrentMonthLeague() {
                    dispatch(.FetchCurrentLeaderboard)
                }
            }
        case let .LogSearch(searchQuery):
            logSearch(searchQuery: searchQuery)
        case let .TrackImpact(contactLog, issue):
            // Trigger impact tracking and animations
            DispatchQueue.main.async {
                ImpactManager.shared?.handleNewAction(contactLog, from: issue, store: Store(state: state, middlewares: []))
            }
        case .SetGlobalCallCount, .SetIssueCallCount, .SetDonateOn, .SetIssueContactCompletion, .SetContacts,
                .SetFetchingContacts, .SetIssues, .SetLoadingStatsError, .SetLoadingIssuesError, .SetLoadingContactsError,
                .GoBack, .GoToRoot, .GoToNext, .ShowWelcomeScreen, .ShowYourImpact, .SetDistrict, .SetSplitDistrict, .SetLowAccuracyMessage, .SetMissingReps, .SetCategoryFilter,
                .SetChangedCampaigns, .ClearChangedCampaign, .RecordCampaignCompletionDeadline, .SetLocationMetadata, .UpdateWeeklyStreak, .IncrementMonthlyAnimals, .TrackImpact, .SetCurrentLeaderboard:
            // no middleware actions for these, including for completeness
            break
        }
    }
}

private func fetchStats(issueID: Int?, dispatch: @escaping Dispatcher) {
    let queue = OperationQueue.main
    let operation = FetchStatsOperation()
    if let issueID {
        operation.issueID = "\(issueID)"
    }
    operation.completionBlock = { [weak operation] in
        if let globalCallCount = operation?.numberOfCalls {
            DispatchQueue.main.async {
                dispatch(.SetGlobalCallCount(globalCallCount))
            }
        }
        if  let issueID, let issueCallCount = operation?.numberOfIssueCalls {
            DispatchQueue.main.async {
                dispatch(.SetIssueCallCount(issueID, issueCallCount))
            }
        }
        if let donateOn = operation?.donateOn {
            DispatchQueue.main.async {
                dispatch(.SetDonateOn(donateOn))
            }
        }

        
        if let error = operation?.error {
            print("Could not load stats: \(error.localizedDescription)..")

            DispatchQueue.main.async {
                dispatch(.SetLoadingStatsError(error))
            }
        }
    }
    queue.addOperation(operation)
}

private func fetchIssues(state: AppState, dispatch: @escaping Dispatcher) {
    // Extract cached location data from state for geographic filtering
    let city = state.city
    let stateParam = state.state
    let county = state.county


    fetchIssuesWithLocation(city: city, county: county, state: stateParam, appState: state, dispatch: dispatch)
}

private func fetchIssuesWithLocation(city: String?, county: String?, state: String?, appState: AppState, dispatch: @escaping Dispatcher) {
    let queue = OperationQueue.main
    

    let operation = FetchAnimalPolicyOperation(city: city, state: state, county: county)
    operation.completionBlock = { [weak operation] in
        if let newCampaigns = operation?.issuesList {
            // Find changed campaigns using cached issues from previous session
            let changedIds = findChangedCampaigns(old: appState.lastKnownIssues, new: newCampaigns)

            // Add new changes to existing ones (keep disappeared campaign IDs)
            var allChangedIds = appState.changedCampaignIds
            allChangedIds.formUnion(Set(changedIds))

            DispatchQueue.main.async {
                dispatch(.SetIssues(newCampaigns))
                dispatch(.SetChangedCampaigns(Array(allChangedIds)))

                // Save issues to cache for change detection across app sessions
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(newCampaigns) {
                    UserDefaults.standard.set(data, forKey: "lastKnownIssues")
                }
            }

            // Update in-memory cache immediately (not on main queue to avoid state conflicts)
            appState.lastKnownIssues = newCampaigns
        } else if let error = operation?.error {
            print("Could not load issues: \(error.localizedDescription)..")

            DispatchQueue.main.async {
                dispatch(.SetLoadingIssuesError(error))
            }
        } else {
            // we don't really return errors from this endpoint so not much use in doing more parsing
            DispatchQueue.main.async {
                dispatch(.SetLoadingContactsError(MiddlewareError.UnknownError))
            }
        }
    }
    queue.addOperation(operation)
}

private func fetchContacts(location: UserLocation, state: AppState, dispatch: @escaping Dispatcher) {
    // Only show loading spinner if we have no cached contacts (new location scenario)
    if state.contacts.isEmpty {
        dispatch(.SetFetchingContacts(true))
    }

    let queue = OperationQueue.main
    let operation = FetchContactsOperation(location: location)
    operation.completionBlock = { [weak operation] in
        dispatch(.SetFetchingContacts(false))
        
        if let district = operation?.district {
            dispatch(.SetDistrict(district))
        }
        if let split = operation?.splitDistrict {
            dispatch(.SetSplitDistrict(split))
        }
        if let lowAccuracyMessage = operation?.lowAccuracyMessage {
            dispatch(.SetLowAccuracyMessage(lowAccuracyMessage))
        }

        // Store location metadata for campaign filtering
        let city = operation?.city
        let county = operation?.county
        let locationState = operation?.state
        dispatch(.SetLocationMetadata(city: city, county: county, state: locationState))
        
        // Refresh issues with new location metadata only if location data changed
        // Only check city and state (county can vary without affecting campaign filtering)
        if city != state.city || locationState != state.state {
            print("🔄 [fetchContacts completion] Location data CHANGED - calling fetchIssuesWithLocation")
            print("   New: city=\(city ?? "nil"), county=\(county ?? "nil"), state=\(locationState ?? "nil")")
            print("   Old: city=\(state.city ?? "nil"), county=\(state.county ?? "nil"), state=\(state.state ?? "nil")")
            fetchIssuesWithLocation(city: city, county: county, state: locationState, appState: state, dispatch: dispatch)
        } else {
            print("✅ [fetchContacts completion] Location data UNCHANGED - skipping duplicate fetchIssuesWithLocation call")
            print("   Location: city=\(city ?? "nil"), county=\(county ?? "nil"), state=\(locationState ?? "nil")")
        }
        
        var missingReps: [String] = []

        if var contacts = operation?.contacts, !contacts.isEmpty {
            // if we get more than one house rep here, select the first one.
            // this is a split district situation and we should let the user
            // pick which one is correct in the future
            let houseReps = contacts.filter({ $0.area == "US House" })
            let senateReps = contacts.filter({ $0.area == "US Senate" })
            if houseReps.count > 1 {
                contacts = contacts.filter({ $0.area != "US House" })
                contacts.append(houseReps[0])
            }
            if houseReps.count < 1 {
                missingReps.append("US House")
            }
            if senateReps.count < 2 {
                missingReps.append("US Senate")
            }
            dispatch(.SetMissingReps(missingReps))
            dispatch(.SetContacts(contacts))

            // Save contacts to cache for future app launches
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(contacts) {
                UserDefaults.standard.set(data, forKey: "cachedContacts")
                UserDefaults.standard.set(Date(), forKey: "contactsFetchTime")
            }
        } else if let error = operation?.error {
            DispatchQueue.main.async {
                dispatch(.SetLoadingContactsError(error))
            }
        } else {
            // TODO: parse error messages from the backend and return specifics
            DispatchQueue.main.async {
                dispatch(.SetLoadingContactsError(MiddlewareError.UnknownError))
            }
        }
    }
    queue.addOperation(operation)
}

private func reportOutcome(log: ContactLog, outcome: Outcome, dispatch: @escaping Dispatcher, updatedCount: Int) {
    let operation = ReportOutcomeOperation(log: log, outcome: outcome, animalsHelpedThisMonth: updatedCount)
    operation.completionBlock = { [weak operation] in
        // If we got an updated issue count, dispatch action to update the state
        if let issueCount = operation?.updatedIssueCount,
           let issueId = Int(log.issueId) {
            DispatchQueue.main.async {
                // Use existing SetIssueCallCount action to update the count
                dispatch(.SetIssueCallCount(issueId, issueCount))
            }
        }
        
        if let error = operation?.error {
            print("Could not report outcome: \(error.localizedDescription)")
        }
    }
    OperationQueue.main.addOperation(operation)
}

private func logSearch(searchQuery: String) {
    // we don't actually care about the result of this so no need to set the callback
    OperationQueue.main.addOperation(LogSearchOperation(searchQuery: searchQuery))
}

private func fetchCurrentLeaderboard(dispatch: @escaping Dispatcher) {
    let queue = OperationQueue.main
    let operation = FetchCurrentMonthLeaderboardOperation()
    operation.completionBlock = { [weak operation] in
        if let participants = operation?.currentLeaderboard, let meta = operation?.currentMeta {
            DispatchQueue.main.async {
                dispatch(.SetCurrentLeaderboard(participants, meta))
                print("🏆 [fetchCurrentLeaderboard] Successfully cached \(participants.count) participants")
            }
        } else if let error = operation?.error {
            print("❌ [fetchCurrentLeaderboard] Error: \\(error.localizedDescription)")
        }
    }
    queue.addOperation(operation)
}

private func isUserInCurrentMonthLeague() -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let now = Date()
    let currentMonthKey = String(format: "%04d-%02d",
                               calendar.component(.year, from: now),
                               calendar.component(.month, from: now))

    let lastLeagueMonth = UserDefaults.standard.string(forKey: UserDefaultsKey.lastLeagueMonth.rawValue)
    return lastLeagueMonth == currentMonthKey
}

private func findChangedCampaigns(old: [AnimalPolicy], new: [AnimalPolicy]) -> [Int] {
    var changedIds: [Int] = []

    // If this is the first app launch (no previous campaigns), don't mark anything as changed
    guard !old.isEmpty else {
        return changedIds
    }

    for newCampaign in new {
        if let oldCampaign = old.first(where: { $0.id == newCampaign.id }) {
            // Existing campaign - check for content changes
            if hasContentChanged(old: oldCampaign, new: newCampaign) {
                changedIds.append(newCampaign.id)
            }
        } else {
            // New campaign - always mark as changed
            changedIds.append(newCampaign.id)
        }
    }

    return changedIds
}

private func hasContentChanged(old: AnimalPolicy, new: AnimalPolicy) -> Bool {
    return old.reason != new.reason
}

// Schedules a one-shot reminder for Friday midday of the current streak week, so users
// still have business hours left to call before offices close for the weekend. Cancels
// any previously scheduled streak reminder first, so this is safe to call on every action.
private func scheduleStreakRiskReminder(currentStreak: Int) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [streakRiskNotificationIdentifier])

    guard currentStreak > 0 else {
        return
    }
    guard let triggerDate = nextFridayMidday(from: Date()), triggerDate > Date() else {
        return
    }

    center.getNotificationSettings { settings in
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent.streakRiskContent(streak: currentStreak)
        let trigger = UNCalendarNotificationTrigger.oneShotTrigger(date: triggerDate)
        let request = UNNotificationRequest(identifier: streakRiskNotificationIdentifier, content: content, trigger: trigger)
        center.add(request)
    }
}

// Targets the Friday of the week AFTER `date`'s week, since this is only ever called
// right after a real action - which already secures the current week's streak, so the
// only week still at risk is the next one.
private func nextFridayMidday(from date: Date) -> Date? {
    var calendar = Calendar.current
    calendar.firstWeekday = 2 // Monday - matches the weekly streak's week definition

    guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start,
          let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart),
          let friday = calendar.date(byAdding: .day, value: 4, to: nextWeekStart) else {
        return nil
    }

    return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: friday)
}

enum MiddlewareError: Error {
   case UnknownError
}
