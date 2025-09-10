//
//  Contact.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/31/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation
import RswiftResources

struct Contact : Decodable {
    let id: String
    let area: String
    let name: String
    let party: String
    let phone: String
    let photoURL: URL?
    let reason: String?
    let state: String?
    let fieldOffices: [AreaOffice]
    
    // ✨ NEW: Corporate support fields
    let email: String?
    let contactType: ContactType
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case area
        case name
        case party
        case phone
        case photoURL
        case reason
        case state
        case fieldOffices = "field_offices"
        case email
        case contactType
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        area = try container.decode(String.self, forKey: .area)
        name = try container.decode(String.self, forKey: .name)
        party = try container.decode(String.self, forKey: .party)
        phone = try container.decode(String.self, forKey: .phone)
        photoURL = (try container.decode(String?.self, forKey: .photoURL)).flatMap(URL.init)
        reason = try container.decode(String.self, forKey: .reason)
        state = try container.decode(String.self, forKey: .state)
        fieldOffices = try container.decode([AreaOffice]?.self, forKey: .fieldOffices) ?? []
        
        // ✨ NEW: Decode new fields with defaults for backward compatibility
        email = try container.decodeIfPresent(String.self, forKey: .email)
        contactType = try container.decodeIfPresent(ContactType.self, forKey: .contactType) ?? .representatives
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
    }

    // 🔄 CHANGED: Updated legacy initializer for political contacts
    init(id: String = "id", area: String = "US House", name: String = "Test Name", party: String = "Party", phone: String = "14155551212", photoURL: URL? = nil, fieldOffices: [AreaOffice] = []) {
        self.id = id
        self.area = area
        self.name = name
        self.party = party
        self.phone = phone
        self.photoURL = photoURL
        self.reason = nil
        self.state = nil
        self.fieldOffices = fieldOffices
        
        // ✨ NEW: Default values for new fields
        self.email = nil
        self.contactType = .representatives
        self.metadata = nil
    }
    
    // ✨ NEW: Initializer for corporate contacts (used when creating from Target)
    init(id: String,
         name: String,
         phone: String? = nil,
         email: String? = nil,
         contactType: ContactType = .corporate,
         metadata: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.phone = phone ?? ""
        self.email = email
        self.contactType = contactType
        self.metadata = metadata
        
        // Political fields (not relevant for corporate but required)
        self.area = ""
        self.party = ""
        self.photoURL = nil
        self.reason = nil
        self.state = nil
        self.fieldOffices = []
    }
    
    // ✨ NEW: Convenience initializer from Target
    init(from target: Target) {
        self.id = target.id
        self.name = target.name
        self.phone = target.phone ?? ""
        self.email = target.email
        self.contactType = .corporate
        // Create metadata dictionary from Target properties
        var metadata: [String: String] = [:]
        if let department = target.department {
            metadata["department"] = department
        }
        if let jobTitle = target.jobTitle {
            metadata["title"] = jobTitle
        }
        self.metadata = metadata.isEmpty ? nil : metadata
        
        // Political fields (not relevant for corporate but required)
        self.area = ""
        self.party = ""
        self.photoURL = nil
        self.reason = nil
        self.state = nil
        self.fieldOffices = []
    }
}

extension Contact: Hashable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Contact {
    // 🔄 CHANGED: Enhanced to support corporate contacts
    func officeDescription() -> String {
        // For corporate contacts, show company and department info
        if contactType == .corporate {
            var description = ""
            if let company = metadata?["company"] {
                description += company
            }
            if let department = metadata?["department"] {
                description += description.isEmpty ? department : " - \(department)"
            }
            return description.isEmpty ? "Corporate Contact" : description
        }
        
        // For political contacts, use existing logic
        switch self.area {
        case "US House", "House":
            // TODO: plumb the district through here too
            return "\(R.string.localizable.usHouse()) \(self.state ?? "")"
        case "US Senate", "Senate":
            return "\(R.string.localizable.usSenate()) \(self.state ?? "")"
        case "StateLower", "StateUpper":
            return "\(R.string.localizable.stateRep()) \(self.state ?? "")"
        case "Governor":
            return "\(R.string.localizable.governor()) \(self.state ?? "")"
        case "AttorneyGeneral":
            return "\(R.string.localizable.attorneyGeneral()) \(self.state ?? "")"
        case "SecretaryOfState":
            return "\(R.string.localizable.secretaryOfState()) \(self.state ?? "")"
        default:
            return ""
        }
    }
    
    // ✨ NEW: Get primary contact method based on contact type
    var primaryContactMethod: String {
        switch contactType {
        case .representatives:
            return phone
        case .corporate:
            // Prefer phone, fallback to email
            if !phone.isEmpty {
                return phone
            } else if let email = email, !email.isEmpty {
                return email
            } else {
                return "No contact info"
            }
        }
    }
    
    // ✨ NEW: Check if contact has email capability
    var hasEmail: Bool {
        return email != nil && !email!.isEmpty
    }
    
    // ✨ NEW: Check if contact has phone capability
    var hasPhone: Bool {
        return !phone.isEmpty
    }
}

extension Contact {
    static func placeholderContact(for area: String) -> [Contact] {
        switch area {
        case "US Senate":
            return [
                    Contact(id: "1234", area: area, name: area, party: area, phone: "", photoURL: nil, fieldOffices: []),
                    Contact(id: "1235", area: area, name: area, party: area, phone: "", photoURL: nil, fieldOffices: [])
                ]
        default:
            // list views will complain if we have mutiple placeholders with the same ID so randomize them
            return [Contact(id: String(Int.random(in: 0..<999)), area: area, name: area, party: area, phone: "", photoURL: nil, fieldOffices: [])]
        }
    }
}

// AreaToNiceString converts an area name to a generic office name that can be used in the interface
func AreaToNiceString(area: String) -> String {
    switch area {
    case "US House", "House":
        return R.string.localizable.groupingUsHouse()
    case "US Senate", "Senate":
        return R.string.localizable.groupingUsSenate()
    // state legislatures call themselves different things by state, so let's use a generic term for all of them
    case "StateLower", "StateUpper":
        return R.string.localizable.groupingStateRep()
    case "Governor":
        return R.string.localizable.groupingGovernor()
    case "AttorneyGeneral":
        return R.string.localizable.groupingAttorneyGeneral()
    case "SecretaryOfState":
        return R.string.localizable.groupingSecretaryOfState()
    default:
        return area
    }
}
