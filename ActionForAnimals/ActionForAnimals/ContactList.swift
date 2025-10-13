//
//  ContactList.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/9/19.
//  Copyright © 2019 5calls. All rights reserved.
//

import Foundation

class ContactList : Decodable {
    let location: String
    let county: String?
    let isSplit: Bool
    let lowAccuracy: Bool?
    let message: String?
    let state: String
    let district: String
    let representatives: [Contact]

    var generalizedLocationID: String {
        return "\(state)-\(district)"
    }
}

