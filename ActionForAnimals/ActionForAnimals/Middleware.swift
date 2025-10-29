//
 //  Middlewares.swift
 //  ActionForAnimals
 //
 //  Created by Christopher Selin on 9/22/23.
 //  Copyright © 2023 5calls. All rights reserved.
 //
 import Foundation

func appMiddleware() -> Middleware<AppState> {
    return { state, action, dispatch in
        switch action {
        case let .FetchStats(issueID):
            fetchStats(issueID: issueID, dispatch: dispatch)
        case .FetchIssues:
            fetchIssues(state: state, dispatch: dispatch)
        case let .FetchContacts(location):
            fetchContacts(location: location, state: state, dispatch: dispatch)
        case let .SetLocation(location):
            fetchContacts(location: location, state: state, dispatch: dispatch)
        case let .ReportOutcome(issue, contactLog, outcome):
            // TODO: migrate ContactLog issueId to Int after UIKit is gone
            // this is always generated in swiftUI from an int so it should always succeed
            if let issueId = Int(contactLog.issueId) {
                // Only track completion for non-skip outcomes
                if outcome.status != "skip" {
                    dispatch(.SetIssueContactCompletion(issueId, contactLog))
                    dispatch(.TrackImpact(contactLog, issue))
                }
            }
            AnalyticsManager.shared.trackEvent(name: "Outcome-\(outcome.status)", path: "/issue/\(issue.slug)/")

            // Only report outcome to server if it's not a skip - skips should not update counts
            if outcome.status != "skip" {
                reportOutcome(log: contactLog, outcome: outcome, dispatch: dispatch)

                // Update weekly streak when user takes an action
                dispatch(.UpdateWeeklyStreak)
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
                .SetChangedCampaigns, .ClearChangedCampaign, .SetLocationMetadata, .UpdateWeeklyStreak, .TrackImpact:
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

    print("🐾 Middleware fetchIssues - AppState values: city=\(city ?? "nil"), state=\(stateParam ?? "nil"), county=\(county ?? "nil")")

    fetchIssuesWithLocation(city: city, county: county, state: stateParam, appState: state, dispatch: dispatch)
}

private func fetchIssuesWithLocation(city: String?, county: String?, state: String?, appState: AppState, dispatch: @escaping Dispatcher) {
    let queue = OperationQueue.main
    
    print("🐾 [fetchIssuesWithLocation] RECEIVED parameters: city=\(city ?? "nil"), state=\(state ?? "nil"), county=\(county ?? "nil")")

    let operation = FetchAnimalPolicyOperation(city: city, state: state, county: county)
    operation.completionBlock = { [weak operation] in
        if let newCampaigns = operation?.issuesList {
            // Find changed campaigns
            let changedIds = findChangedCampaigns(old: appState.issues, new: newCampaigns)

            // Add new changes to existing ones (keep disappeared campaign IDs)
            var allChangedIds = appState.changedCampaignIds
            allChangedIds.formUnion(Set(changedIds))

            DispatchQueue.main.async {
                dispatch(.SetIssues(newCampaigns))
                dispatch(.SetChangedCampaigns(Array(allChangedIds)))
            }
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
    dispatch(.SetFetchingContacts(true))

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
        print("🐾 Middleware dispatching SetLocationMetadata - city: \(city ?? "nil"), county: \(county ?? "nil"), state: \(locationState ?? "nil")")
        dispatch(.SetLocationMetadata(city: city, county: county, state: locationState))
        
        // Refresh issues with new location metadata
        // Call fetchIssues directly with the location data we just received
        print("🐾 Middleware calling fetchIssues directly with new location data")
        fetchIssuesWithLocation(city: city, county: county, state: locationState, appState: state, dispatch: dispatch)
        
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

private func reportOutcome(log: ContactLog, outcome: Outcome, dispatch: @escaping Dispatcher) {
    let operation = ReportOutcomeOperation(log: log, outcome: outcome)
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

enum MiddlewareError: Error {
   case UnknownError
}
