//
//  AreaOffice.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 2/4/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation

struct AreaOffice: Codable, Identifiable {
    let city: String
    let phone: String
    
    var id: Int {
        return phone.hashValue
    }
}
