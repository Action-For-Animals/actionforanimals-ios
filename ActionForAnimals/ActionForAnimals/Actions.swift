//
//  Action.swift
//  ActionForAnimals
//
//  Created by Christopher Selin on 9/22/23.
//  Copyright © 2023 5calls. All rights reserved.
//
import Foundation

enum Action {
    case ShowWelcomeScreen
    case FetchStats(Int?)
    case SetGlobalCallCount(Int)
    case SetIssueCallCount(Int,Int)
    case SetIssueContactCompletion(Int,ContactLog)
    case SetDonateOn(Bool)
    case FetchIssues
    case SetIssues([AnimalPolicy])
    case FetchContacts(UserLocation)
    case SetContacts([Contact])
    case SetDistrict(String)
    case SetSplitDistrict(Bool)
    case SetLowAccuracyMessage(String?)
    case SetLocationMetadata(city: String?, county: String?, state: String?)
    case SetLocation(UserLocation)
    case SetCategoryFilter(String)
    case ReportOutcome(AnimalPolicy, ContactLog, Outcome)
    case SetFetchingContacts(Bool)
    case SetLoadingStatsError(Error)
    case SetLoadingIssuesError(Error)
    case SetLoadingContactsError(Error)
    case GoBack
    case GoToRoot
    case GoToNext(AnimalPolicy, [Contact], IssueDetailNavModel.ActionType)
    case SetMissingReps([String])
    case LogSearch(String)
    case SetChangedCampaigns([Int])
    case ClearChangedCampaign(Int)
}
