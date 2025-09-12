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
            fetchIssues(dispatch: dispatch)
        case let .FetchContacts(location):
            fetchContacts(location: location, dispatch: dispatch)
        case let .SetLocation(location):
            fetchContacts(location: location, dispatch: dispatch)
        case let .ReportOutcome(issue, contactLog, outcome):
            // TODO: migrate ContactLog issueId to Int after UIKit is gone
            // this is always generated in swiftUI from an int so it should always succeed
            if let issueId = Int(contactLog.issueId) {
                dispatch(.SetIssueContactCompletion(issueId, contactLog))
            }
            AnalyticsManager.shared.trackEvent(name: "Outcome-\(outcome.status)", path: "/issue/\(issue.slug)/")
            
            // Only report outcome to server if it's not a skip - skips should not update counts
            if outcome.status != "skip" {
                reportOutcome(log: contactLog, outcome: outcome, dispatch: dispatch)
            }
        case let .LogSearch(searchQuery):
            logSearch(searchQuery: searchQuery)
        case .SetGlobalCallCount, .SetIssueCallCount, .SetDonateOn, .SetIssueContactCompletion, .SetContacts,
                .SetFetchingContacts, .SetIssues, .SetLoadingStatsError, .SetLoadingIssuesError, .SetLoadingContactsError,
                .GoBack, .GoToRoot, .GoToNext, .ShowWelcomeScreen, .SetDistrict, .SetSplitDistrict, .SetMissingReps, .SetCategoryFilter:
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

private func fetchIssues(dispatch: @escaping Dispatcher) {
    let queue = OperationQueue.main
    let operation = FetchAnimalPolicyOperation()
    operation.completionBlock = { [weak operation] in
        if let issues = operation?.issuesList {
            DispatchQueue.main.async {
                dispatch(.SetIssues(issues))
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

private func fetchContacts(location: UserLocation, dispatch: @escaping Dispatcher) {
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

enum MiddlewareError: Error {
   case UnknownError
}
