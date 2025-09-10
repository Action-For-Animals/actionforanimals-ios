//
//  CategoryHelper.swift
//  ActionForAnimals
//

import Foundation

enum CategoryKey: String, CaseIterable {
    case farmed = "farmed"
    case wildlife = "wildlife"
    case companion = "companion"
    case climate = "climate"
    case entertainment = "entertainment"
    case testing = "testing"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .farmed: return "Farmed"
        case .wildlife: return "Wildlife"
        case .companion: return "Companion"
        case .climate: return "Climate"
        case .entertainment: return "Entertainment"
        case .testing: return "Testing"
        case .none: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .farmed: return "category-farmed"
        case .wildlife: return "category-wildlife"
        case .companion: return "category-companion"
        case .climate: return "category-climate"
        case .entertainment: return "category-entertainment"
        case .testing: return "category-testing"
        case .none: return "category-generic"
        }
    }
}

struct CategoryHelper {
    
    /// Get the primary category key from an AnimalPolicy
    static func primaryCategoryKey(from issue: AnimalPolicy) -> CategoryKey {
        guard let rawName = issue.categories.first?.name else { return .none }
        let key = normalize(rawName)
        
        switch key {
        case "farmed": return .farmed
        case "wildlife": return .wildlife
        case "companion": return .companion
        default: return .none // All other categories map to .none
        }
    }
    
    /// Get the icon name for a category
    static func iconName(for issue: AnimalPolicy) -> String {
        return primaryCategoryKey(from: issue).iconName
    }
    
    /// Check if an issue matches a category filter
    static func issueMatches(issue: AnimalPolicy, categoryFilter: CategoryKey) -> Bool {
        let primaryKey = primaryCategoryKey(from: issue)
        return primaryKey == categoryFilter
    }
    
    /// Get all available category filters from a list of issues
    static func availableCategories(from issues: [AnimalPolicy]) -> [CategoryKey] {
        let categories = Set(issues.map { primaryCategoryKey(from: $0) })
        return CategoryKey.allCases.filter { categories.contains($0) && $0 != .none }
    }
    
    /// Normalize category names for consistent matching
    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .lowercased()
         .replacingOccurrences(of: "_", with: "-")
         .replacingOccurrences(of: " ", with: "")
    }
}
