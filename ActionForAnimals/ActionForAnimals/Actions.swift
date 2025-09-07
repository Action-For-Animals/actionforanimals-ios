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
    case SetIssueContactCompletion(Int,String)
    case SetDonateOn(Bool)
    case FetchIssues
    case SetIssues([Issue])
    case FetchContacts(UserLocation)
    case SetContacts([Contact])
    case SetDistrict(String)
    case SetSplitDistrict(Bool)
    case SetLocation(UserLocation)
    case ReportOutcome(Issue, ContactLog, Outcome)
    case SetFetchingContacts(Bool)
    case SetLoadingStatsError(Error)
    case SetLoadingIssuesError(Error)
    case SetLoadingContactsError(Error)
    case GoBack
    case GoToRoot
    case GoToNext(Issue, [Contact])
    case SetMissingReps([String])
    case LogSearch(String)
}
