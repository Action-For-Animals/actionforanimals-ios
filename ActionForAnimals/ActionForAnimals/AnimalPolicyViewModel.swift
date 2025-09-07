//
//  AnimalPolicyViewModel.swift
//  ActionForAnimals
//
//  Created by Indrajit on 17/10/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation

protocol AnimalPolicyViewModel {

    var issues: [AnimalPolicy] { get }

    init(issues:[AnimalPolicy])
    func numberOfSections() -> Int
    func numberOfRowsInSection(section: Int) -> Int
    func hasNoData() -> Bool
    func issueForIndexPath(indexPath: IndexPath) -> AnimalPolicy
    func titleForHeaderInSection(section: Int) -> String
}

extension AnimalPolicyViewModel {
    var categorizedIssues: [CategorizedAnimalPolicyViewModel] {
        var categoryViewModels = Set<CategorizedAnimalPolicyViewModel>()
        for issue in issues {
            for category in issue.categories {

                if let categorized = categoryViewModels.first(where: { $0.category == category }) {
                    categorized.issues.append(issue)
                } else {
                    categoryViewModels.insert(CategorizedAnimalPolicyViewModel(category: category, issues: [issue]))
                }
            }
        }
        return Array(categoryViewModels).sorted(by: { $0.category < $1.category })
    }
}

// Shows all issues - grouped by categories.
struct AllIssuesViewModel: AnimalPolicyViewModel {
    let issues: [AnimalPolicy]

    init(issues: [AnimalPolicy]) {
        self.issues = issues
    }

    func numberOfSections() -> Int {
        // As many section as there are unique categories.
        return categorizedIssues.count
    }

    func numberOfRowsInSection(section: Int) -> Int {
        return categorizedIssues[section].issues.count
    }

    func hasNoData() -> Bool {
        return categorizedIssues.count == 0
    }

    func issueForIndexPath(indexPath: IndexPath) -> AnimalPolicy {
        return categorizedIssues[indexPath.section].issues[indexPath.row]
    }

    func titleForHeaderInSection(section: Int) -> String {
        // Category name as section header.
        return categorizedIssues[section].name
    }
}

// Shows only the active issues.
struct ActiveIssuesViewModel: AnimalPolicyViewModel {
    private let activeIssues: [AnimalPolicy]
    let issues: [AnimalPolicy]

    init(issues: [AnimalPolicy]) {
        self.issues = issues
        activeIssues = issues.filter { $0.active }
    }

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfRowsInSection(section: Int) -> Int {
        return activeIssues.count
    }

    func hasNoData() -> Bool {
        return activeIssues.count == 0
    }

    func issueForIndexPath(indexPath: IndexPath) -> AnimalPolicy {
        return activeIssues[indexPath.row]
    }

    func titleForHeaderInSection(section: Int) -> String {
        return R.string.localizable.takeActionForAnimals()
    }
}
