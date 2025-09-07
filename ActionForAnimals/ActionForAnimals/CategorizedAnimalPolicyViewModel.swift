//
//  CategorizedIssuesViewModel.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/29/19.
//  Copyright © 2019 5calls. All rights reserved.
//

import Foundation

class CategorizedAnimalPolicyViewModel: Identifiable {
    let category: Category
    var issues: [AnimalPolicy]

    var name: String {
        return category.name
    }
    
    var id: Int {
        return name.hashValue
    }

    init(category: Category, issues: [AnimalPolicy]) {
        self.category = category
        self.issues = issues
    }
}

extension CategorizedAnimalPolicyViewModel : Hashable {
    static func == (lhs: CategorizedAnimalPolicyViewModel, rhs: CategorizedAnimalPolicyViewModel) -> Bool {
        return lhs.category == rhs.category
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.category)
    }
}
