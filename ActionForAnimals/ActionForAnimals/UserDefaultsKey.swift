//
//  UserDefaultsKey.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/30/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation

enum UserDefaultsKey : String {
    case hasShownWelcomeScreen
    
    case locationDisplay
    case locationType
    case locationValue

    // Location metadata for campaign filtering
    case locationCity
    case locationCounty
    case locationState
    
    case selectedCategoryFilter // user's preferred animal category filter
    
    case issueCompletionCache // a cached map of issue id to contact ids regarding completed calls
    
    case hasSeenFirstCallInstructions
    case reminderEnabled

    case appVersion // The current CFBundleShortVersionString
    case countOfCallsForRatingPrompt
    
    case lastAskedForNotificationPermission

    case selectIssuePath
    
    case callerID // an anoymous unique id, sometimes the old firebase userid
    case callingGroup // a calling group is a group that tallies their calls together

    case weeklyStreak // current weekly streak count
    case lastActionWeek // last week user took an action (YYYY-ww format)
    case animalsHelpedThisMonth // animals helped in current month for league
    case lastMonthlyCountUpdate // last month when counter was updated (YYYY-MM format)
    case lastLeagueMonth // last month user joined a league (YYYY-MM format)

    case completedCampaignDeadlines // map of issue id -> deadline as of when the user finished it
    case lastFullCompletionDate // map of issue id -> date the user last fully completed it
}
