//
//  Contact.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/31/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation
import RswiftResources

struct Contact : Codable {
    let id: String
    let area: String
    let name: String
    let party: String
    let phone: String
    private let photoURLString: String?
    let reason: String?
    let state: String?
    let fieldOffices: [AreaOffice]

    // ✨ NEW: Corporate support fields
    let email: String?
    private let contactTypeRaw: ContactType?
    let metadata: [String: String]?

    // Computed properties for special handling
    var photoURL: URL? {
        photoURLString.flatMap(URL.init)
    }

    var contactType: ContactType {
        contactTypeRaw ?? .representatives
    }

    enum CodingKeys: String, CodingKey {
        case id
        case area
        case name
        case party
        case phone
        case photoURLString = "photoURL"
        case reason
        case state
        case fieldOffices = "field_offices"
        case email
        case contactTypeRaw = "contactType"
        case metadata
    }

    // 🔄 CHANGED: Updated legacy initializer for political contacts
    init(id: String = "id", area: String = "US House", name: String = "Test Name", party: String = "Party", phone: String = "14155551212", photoURL: URL? = nil, fieldOffices: [AreaOffice] = []) {
        self.id = id
        self.area = area
        self.name = name
        self.party = party
        self.phone = phone
        self.photoURLString = photoURL?.absoluteString
        self.reason = nil
        self.state = nil
        self.fieldOffices = fieldOffices

        // ✨ NEW: Default values for new fields
        self.email = nil
        self.contactTypeRaw = .representatives
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
        self.contactTypeRaw = contactType
        self.metadata = metadata

        // Political fields (not relevant for corporate but required)
        self.area = ""
        self.party = ""
        self.photoURLString = nil
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
        self.contactTypeRaw = .corporate
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
        self.photoURLString = nil
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
        
        // For political contacts, use the reason text if available, otherwise fall back to area
        return self.reason ?? self.area ?? ""
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
    return area
}
