//
//  ScriptReplacements.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 12/12/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import Foundation
import RegexBuilder

struct ScriptReplacements {
    
    static func replacing(script: String, contact: Contact, location: UserLocation?) -> String {
        var replacedScript = ScriptReplacements.chooseSubscript(script: script, contact: contact)

        replacedScript = ScriptReplacements.replacingContact(script: replacedScript, contact: contact)

        if let location {
            replacedScript = ScriptReplacements.replacingLocation(script: replacedScript, location: location)
        }

        replacedScript = ScriptReplacements.replacingUserName(script: replacedScript)

        return replacedScript
    }
    
    // Method for corporate targets - now requires issue context for corporateInfo
    static func replacing(script: String, target: Target, issue: AnimalPolicy, location: UserLocation?) -> String {
        var replacedScript = ScriptReplacements.replacingTarget(script: script, target: target, issue: issue)

        if let location {
            replacedScript = ScriptReplacements.replacingLocation(script: replacedScript, location: location)
        }

        replacedScript = ScriptReplacements.replacingUserName(script: replacedScript)

        return replacedScript
    }
    
    // Generic method that works with either contact or target
    static func replacing(script: String, contact: Contact? = nil, target: Target? = nil, issue: AnimalPolicy? = nil, location: UserLocation?) -> String {
        if let contact = contact {
            return replacing(script: script, contact: contact, location: location)
        } else if let target = target, let issue = issue {
            return replacing(script: script, target: target, issue: issue, location: location)
        } else {
            // Just replace location and user name if provided
            var replacedScript = script
            if let location = location {
                replacedScript = ScriptReplacements.replacingLocation(script: replacedScript, location: location)
            }
            replacedScript = ScriptReplacements.replacingUserName(script: replacedScript)
            return replacedScript
        }
    }
    
    static func chooseSubscript(script: String, contact: Contact) -> String {
        let houseIntroPattern = /\*{2}WHEN CALLING HOUSE:\*{2}\n/
        let senateIntroPattern = /\*{2}WHEN CALLING SENATE:\*{2}\n/
        
        func wholeRegex(_ introPattern: Regex<Substring>) -> Regex<Substring> {
            return Regex {
                introPattern
                OneOrMore(.anyNonNewline)
                OneOrMore(.newlineSequence)
            }
        }
        if contact.area == "US House" || contact.area == "House" {
            let replacedScript = script.replacing(Regex(houseIntroPattern), with: "")
            return replacedScript.replacing(wholeRegex(senateIntroPattern), with: "")
        } else if contact.area == "US Senate" || contact.area == "Senate" {
            let replacedScript =  script.replacing(Regex(senateIntroPattern), with: "")
            return replacedScript.replacing(wholeRegex(houseIntroPattern), with: "")
        }
        return script
    }
    
    // Enhanced to handle both political and corporate contacts
    static func replacingContact(script: String, contact: Contact) -> String {
        var replacedScript = script
        
        // Political contact patterns
        let politicalPattern = /\[REP\/SEN NAME\]|\[SENATOR\/REP NAME\]|\[SENATOR NAME\]|\[REPRESENTATIVE NAME\]/
        let politicalTemplate = contact.title.map { $0 + " " + contact.name } ?? contact.name
        replacedScript = replacedScript.replacing(Regex(politicalPattern), with: politicalTemplate)
            
        return replacedScript
    }
    
    // Corporate target replacement method - updated for new schema
    static func replacingTarget(script: String, target: Target, issue: AnimalPolicy) -> String {
        var replacedScript = script
        
        // Replace target-specific patterns
        let targetNamePattern = /\*{2}\[TARGET_NAME\]\*{2}|\[TARGET_NAME\]/
        replacedScript = replacedScript.replacing(Regex(targetNamePattern), with: target.name)
        
        // Replace company information from issue.corporateInfo
        let companyPattern = /\*{2}\[TARGET_COMPANY\]\*{2}|\[TARGET_COMPANY\]|\[COMPANY\]/
        if let company = issue.corporateInfo?.company {
            replacedScript = replacedScript.replacing(Regex(companyPattern), with: company)
        }
        
        // Replace industry information
        let industryPattern = /\*{2}\[INDUSTRY\]\*{2}|\[INDUSTRY\]/
        if let industry = issue.corporateInfo?.industry {
            replacedScript = replacedScript.replacing(Regex(industryPattern), with: industry)
        }
        
        // Replace CEO/leadership patterns with target name (assuming they're leadership)
        let ceoPattern = /\*{2}\[CEO\]\*{2}|\[CEO\]/
        replacedScript = replacedScript.replacing(Regex(ceoPattern), with: target.name)
        
        // Replace department/title patterns
        let departmentPattern = /\*{2}\[DEPARTMENT\]\*{2}|\[DEPARTMENT\]/
        if let department = target.department {
            replacedScript = replacedScript.replacing(Regex(departmentPattern), with: department)
        }
        
        let titlePattern = /\*{2}\[TARGET_TITLE\]\*{2}|\[TARGET_TITLE\]/
        if let jobTitle = target.jobTitle {
            replacedScript = replacedScript.replacing(Regex(titlePattern), with: jobTitle)
        }
        
        return replacedScript
    }
    
    static func replacingLocation(script: String, location: UserLocation) -> String {
        let pattern = /\[CITY,\s?ZIP\]|\[CITY,\s?STATE\]|\*{2}\[CITY, ZIP\]\*{2}/
        return script.replacing(Regex(pattern), with: location.locationDisplay)
    }

    static func replacingUserName(script: String) -> String {
        let pattern = /\*{2}\[Name\]\*{2}|\*{2}\[NAME\]\*{2}|\[Name\]|\[NAME\]/
        let userProfile = ProfileManager.shared.currentProfile

        // Check if user has set a meaningful name
        let hasValidFirstName = userProfile.firstName != nil && !userProfile.firstName!.isEmpty

        if hasValidFirstName {
            // Use the actual name (displayName handles firstName + lastName logic)
            return script.replacing(Regex(pattern), with: userProfile.displayName)
        } else {
            // User hasn't set their name - keep placeholder
            return script.replacing(Regex(pattern), with: "[Your Name]")
        }
    }
}

// Enhanced Contact extension to support corporate contacts
extension Contact {
    var title: String? {
        // For corporate contacts, use department or area (which maps to department)
        if contactType == .corporate {
            return area != "Corporate" ? area : nil
        }
        
        // For political contacts, use existing logic
        switch self.area {
        case "US House", "House":
            return R.string.localizable.titleUsHouse()
        case "US Senate", "Senate":
            return R.string.localizable.titleUsSenate()
        case "StateLower", "StateUpper":
            return R.string.localizable.titleStateRep()
        case "Governor":
            return R.string.localizable.titleGovernor()
        case "AttorneyGeneral":
            return R.string.localizable.titleAttorneyGeneral()
        case "SecretaryOfState":
            return R.string.localizable.titleSecretaryOfState()
        default:
            return nil
        }
    }
}

// Target extension for consistent API - updated for new schema
extension Target {
    var displayName: String {
        if let department = department {
            return "\(name) - \(department)"
        }
        return name
    }
    
    var title: String? {
        return jobTitle ?? department
    }
}
