//
//  Issue.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/31/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation
import RswiftResources

struct AnimalPolicy: Identifiable, Decodable {
    struct Stats: Decodable {
        let calls: Int?
        let emails: Int?
        let totalActions: Int
        
        enum CodingKeys: String, CodingKey {
            case calls, emails
            case totalActions = "total_actions"
        }
        
        // Memberwise initializer for direct creation (e.g., in previews)
        init(calls: Int?, emails: Int?, totalActions: Int) {
            self.calls = calls
            self.emails = emails
            self.totalActions = totalActions
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            calls = try container.decodeIfPresent(Int.self, forKey: .calls)
            emails = try container.decodeIfPresent(Int.self, forKey: .emails)
            // Default to calls count if total_actions missing
            totalActions = try container.decodeIfPresent(Int.self, forKey: .totalActions) ?? calls ?? 0
        }
    }
    
    let id: Int
    let meta: String
    let name: String
    let slug: String
    let reason: String
    let script: String?
    let categories: [Category]
    let active: Bool
    let outcomeModels: [Outcome]
    let contactType: ContactType
    let contactAreas: [String]
    let createdAt: Date
    let status: String
    let stats: Stats
    let animalsHelped: Int?

    // Corporate campaign support
    let targets: [Target]?
    let actions: Actions?
    let corporateInfo: CorporateInfo?
    
    // convenience
    var callCount: Int { stats.calls ?? 0 }

    // Additional convenience properties
    var emailCount: Int { stats.emails ?? 0 }
    var totalActionCount: Int { stats.totalActions }
    var animalsHelpedPerAction: Int { animalsHelped ?? 1 }
    
    // Action For Animals - Not used for now - until we figure it out
    var shareImageURL: URL {
        return URL(string: "")!
    }

    var shareURL: URL {
        return URL(string: String(format: "https://actionforanimals.substack.com/p/%@", self.slug.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self.slug))!
    }
    
    var hasHouse: Bool { contactAreas.contains("US House") }
    
    var hasSenate: Bool { contactAreas.contains("US Senate") }
    
    // Only applies to political campaigns
    var isCongressionalIssue: Bool {
        contactType == .representatives && (hasHouse || hasSenate)
    }
    
    // Check if this is a batch email campaign
    var isBatchEmailCampaign: Bool {
        return contactType == .corporate &&
               actions?.email?.enabled == true &&
               actions?.email?.distributionMethod == "batch"
    }
    
    // contactsForIssue takes a list of all contacts and returns a consistently sorted list of
    // contacts based on the areas for this issue
    // Only works for political campaigns, corporate campaigns use targets directly
    func contactsForIssue(allContacts: [Contact]) -> [Contact] {
        guard contactType == .representatives else {
            return [] // Corporate campaigns use targets instead
        }
        
        var sortedContacts: [Contact] = []
        
        for area in sortedContactAreas(areas: contactAreas) {
            sortedContacts.append(contentsOf: allContacts.filter({ area == $0.area }))
        }

        return sortedContacts
    }
    
    // returns any contacts that should be displayed on the issue, but aren't actually targetted
    // this ensures both house and senate reps are displayed even when the issue specifically targets one or the other
    // Only applies to political campaigns
    func irrelevantContacts(allContacts: [Contact]) -> [Contact] {
        guard contactType == .representatives else {
            return [] // Corporate campaigns don't have irrelevant contacts
        }
        
        var irrelevantContacts: [Contact] = []
        
        if hasHouse && !hasSenate {
            let senateContacts = allContacts.filter { $0.area == "US Senate" }
            irrelevantContacts.append(contentsOf: senateContacts)
        }
        
        if hasSenate && !hasHouse {
            let houseContacts = allContacts.filter { $0.area == "US House" }
            irrelevantContacts.append(contentsOf: houseContacts)
        }
        return irrelevantContacts
    }
    
    // returns the contact area that is not relevant to a congressional issue
    // either US House, US Senate, or nil
    // Only applies to political campaigns
    func irrelevantContactArea() -> String? {
        guard contactType == .representatives else {
            return nil // Corporate campaigns don't have irrelevant areas
        }
        
        if hasHouse && !hasSenate {
            return "US Senate"
        }
        
        if hasSenate && !hasHouse {
            return "US House"
        }
        
        return nil
    }
    
    // sortedContactAreas takes a list of contact areas and orders them in our preferred order,
    // we should always order them properly on the server but let's do this to be sure
    func sortedContactAreas(areas: [String]) -> [String] {
        var contactAreas: [String] = []
        
        // TODO: convert these to enums when they are parsed in json
        for area in ["StateLower", "StateUpper", "US House", "US Senate", "Governor", "AttorneyGeneral", "SecretaryOfState"] {
            if areas.contains(area) {
                contactAreas.append(area)
            }
        }
        
        // add any others at the end
        contactAreas.append(contentsOf: areas.filter({ !["StateLower", "StateUpper", "US House", "US Senate", "Governor", "AttorneyGeneral", "SecretaryOfState"].contains($0) }))
                
        return contactAreas
    }
    
    var markdownIssueReason: AttributedString {
        do {
            return try AttributedString(markdown: self.reason, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            // TODO: notify us somehow that markdown parsing failed
            return AttributedString("Could not parse issue markdown, email [howdyxfa@gmail.com](mailto:howdyxfa@gmail.com)")
        }
    }
    
    // Enhanced to support different action types and corporate campaigns
    func markdownScript(for actionType: IssueDetailNavModel.ActionType, contact: Contact? = nil, target: Target? = nil, location: UserLocation?) -> AttributedString {
        let scriptText: String
        
        switch contactType {
        case .representatives:
            // Use legacy script or new actions
            if let actions = actions {
                switch actionType {
                case .call:
                    scriptText = actions.call?.script ?? script ?? ""
                case .email:
                    scriptText = actions.email?.template ?? script ?? ""
                case .batchEmail:
                    scriptText = actions.email?.template ?? script ?? ""
                }
            } else {
                scriptText = script ?? ""
            }
            
        case .corporate:
            // Use corporate actions
            if let actions = actions {
                switch actionType {
                case .call:
                    scriptText = actions.call?.script ?? script ?? ""
                case .email:
                    scriptText = actions.email?.template ?? script ?? ""
                case .batchEmail:
                    scriptText = actions.email?.template ?? script ?? ""
                }
            } else {
                scriptText = script ?? ""
            }
        }
        
        do {
            let processedScript: String
            if let contact = contact {
                processedScript = ScriptReplacements.replacing(script: scriptText, contact: contact, location: location)
            } else if let target = target {
                processedScript = ScriptReplacements.replacing(script: scriptText, target: target, issue: self, location: location)
            } else {
                processedScript = scriptText
            }
            
            return try AttributedString(markdown: processedScript, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            // TODO: notify us somehow that markdown parsing failed
            return AttributedString("Could not parse script markdown, email [howdyxfa@gmail.com](mailto:howdyxfa@gmail.com)")
        }
    }
    
    // Legacy method maintained for backward compatibility
    func markdownIssueScript(contact: Contact, location: UserLocation?) -> AttributedString {
        return markdownScript(for: .call, contact: contact, location: location)
    }
    
    // Get email subject for corporate campaigns
    func emailSubject(for target: Target?) -> String {
        return actions?.email?.subject ?? "Action for Animals Campaign"
    }
    
    // Check if specific action types are enabled
    func isCallEnabled() -> Bool {
        return actions?.call?.enabled ?? true // Default to true for backward compatibility
    }
    
    func isEmailEnabled() -> Bool {
        return actions?.email?.enabled ?? false
    }
}

// Supporting models for corporate campaigns
struct Target: Identifiable, Decodable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let department: String?
    let jobTitle: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, department
        case jobTitle = "title"
    }
}

struct CorporateInfo: Decodable {
    let company: String
    let industry: String?
    let ticker: String?
    let headquarters: String?
}

struct Actions: Decodable {
    let call: CallAction?
    let email: EmailAction?
}

struct CallAction: Decodable {
    let enabled: Bool
    let script: String
}

struct EmailAction: Decodable {
    let enabled: Bool
    let distributionMethod: String?
    let subject: String
    let template: String
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case distributionMethod = "distribution_method"
        case subject
        case template
    }
}

// Action type enum
enum ActionType {
    case call
    case email
    case batchEmail
}

extension AnimalPolicy: Equatable, Hashable {
    static func == (lhs: AnimalPolicy, rhs: AnimalPolicy) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Contact Extension for Target Conversion
extension Contact {
    static func fromTarget(_ target: Target) -> Contact {
        return Contact(from: target)
    }
}
