//
//  Store.swift
//  ActionForAnimals
//
//  Created by Christopher Selin on 9/22/23.
//  Copyright © 2023 5calls. All rights reserved.
//
import Foundation
import SwiftUI

typealias Dispatcher = (Action) -> Void

typealias Reducer<State: ReduxState> = (_ state: State, _ action: Action) -> State
typealias Middleware<StoreState: ReduxState> = (StoreState, Action, @escaping Dispatcher) -> Void

protocol ReduxState { }

class Store: ObservableObject {
    @Published var state: AppState
    var middlewares: [Middleware<AppState>]

    init(state: AppState, middlewares: [Middleware<AppState>] = []) {
        self.state = state
        self.middlewares = middlewares
    }

    func dispatch(action: Action) {
        DispatchQueue.main.async {
            self.state = self.reduce(self.state, action)
        }

        // run all middlewares
        middlewares.forEach { middleware in
            middleware(state, action, dispatch)
        }
    }
    
    func reduce(_ oldState: AppState, _ action: Action) -> AppState {
        let state = oldState
        switch action {
        case .ShowWelcomeScreen:
            state.showWelcomeScreen = true
        case .ShowYourImpact:
            state.showYourImpact = true
        case let .SetGlobalCallCount(globalCallCount):
            state.globalCallCount = globalCallCount
        case let .SetIssueCallCount(issueID, count):
            state.issueCallCounts[issueID] = count
        case let .SetDonateOn(donateOn):
            state.donateOn = donateOn
        case let .SetIssueContactCompletion(issueID, contactLog):
            var existingCompletions = state.issueCompletion[issueID] ?? []
            existingCompletions.append(contactLog)
            state.issueCompletion[issueID] = existingCompletions

        case let .SetFetchingContacts(fetching):
            state.fetchingContacts = fetching
        case let .SetIssues(issues):
            state.issueFetchTime = Date()
            state.issues = issues
        case let .SetContacts(contacts):
            state.contacts = contacts
        case let .SetDistrict(district):
            let oldDistrict = state.district
            state.district = district
        case let .SetSplitDistrict(splitDistrict):
            state.isSplitDistrict = splitDistrict
        case let .SetLowAccuracyMessage(message):
            state.lowAccuracyMessage = message
        case let .SetLocationMetadata(city, county, state_param):
            state.city = city
            state.county = county
            state.state = state_param
        case let .SetMissingReps(missingReps):
            state.missingReps = missingReps
        case let .SetLocation(location):
            state.location = location
            // Clear contacts when location changes so spinner shows for new area
            state.contacts = []
            // Also clear cached contacts since they're for the old location
            UserDefaults.standard.removeObject(forKey: "cachedContacts")
            UserDefaults.standard.removeObject(forKey: "contactsFetchTime")
        case let .SetCategoryFilter(filter):
            state.selectedCategoryFilter = filter
        case let .SetLoadingStatsError(error):
            state.statsLoadingError = error
        case let .SetLoadingIssuesError(error):
            state.issueLoadingError = error
        case let .SetLoadingContactsError(error):
            state.contactsLoadingError = error
        case .GoBack:
           if state.issueRouter.path.isEmpty {
               state.issueRouter.selectedIssue = nil
           } else {
               state.issueRouter.path.removeLast()
           }
       case .GoToRoot:
           state.issueRouter.selectedIssue = nil
           state.issueRouter.path = NavigationPath()
       case let .GoToNext(issue, nextContacts, actionType):
           if nextContacts.count >= 1 {
               state.issueRouter.path.append(IssueDetailNavModel(issue: issue, contacts: nextContacts, actionType: actionType))
           } else {
               state.issueRouter.path.append(IssueDoneNavModel(issue: issue, type: "done"))
           }
        case let .SetChangedCampaigns(changedIds):
            state.changedCampaignIds = Set(changedIds)
        case let .ClearChangedCampaign(campaignId):
            state.changedCampaignIds.remove(campaignId)
        case .UpdateWeeklyStreak:
            updateWeeklyStreak(state: state)
        case let .IncrementMonthlyAnimals(animalsHelped):
            state.animalsHelpedThisMonth += animalsHelped
        case let .SetCurrentLeaderboard(participants, meta):
            state.cachedCurrentLeaderboard = participants
            state.cachedCurrentMeta = meta
        case .FetchStats, .FetchIssues, .FetchCurrentLeaderboard,
                .FetchContacts(_),
                .ReportOutcome(_, _, _),
                .LogSearch(_),
                .TrackImpact(_, _):
            // handled in middleware
            break
        }
        return state
    }

    func updateWeeklyStreak(state: AppState) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)
        let now = Date()
        let currentWeekString = weekString(for: now, calendar: calendar)


        // If this is the first action this week
        if state.lastActionWeek != currentWeekString {
            if let lastWeek = state.lastActionWeek {
                let lastWeekDate = dateFromWeekString(lastWeek, calendar: calendar)
                let currentWeekDate = calendar.dateInterval(of: .weekOfYear, for: now)!.start

                let lastWeekStart = calendar.dateInterval(of: .weekOfYear, for: lastWeekDate)!.start
                let expectedPreviousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekDate)!

                // Check if last action was in the previous consecutive week
                if lastWeekStart == expectedPreviousWeek {
                    // Consecutive week - increment streak
                    state.weeklyStreak += 1
                } else {
                    // Gap in weeks - reset streak to 1
                    state.weeklyStreak = 1
                }
            } else {
                // First ever action - start streak
                state.weeklyStreak = 1
            }

            state.lastActionWeek = currentWeekString
        }
        // If already took action this week, don't change streak
    }

    private func weekString(for date: Date, calendar: Calendar) -> String {
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return String(format: "%04d-%02d", year, week)
    }

    private func dateFromWeekString(_ weekString: String, calendar: Calendar) -> Date {
        let components = weekString.split(separator: "-")
        guard components.count == 2,
              let year = Int(components[0]),
              let week = Int(components[1]) else {
            return Date()
        }

        var dateComponents = DateComponents()
        dateComponents.yearForWeekOfYear = year
        dateComponents.weekOfYear = week
        dateComponents.weekday = 2 // Monday
        return calendar.date(from: dateComponents) ?? Date()
    }

}
