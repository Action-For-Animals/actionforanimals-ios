//
//  FetchUserStatsOperation.swift
//  ActionForAnimals
//
//  Created by Mel Stanley on 1/31/18.
//  Copyright © 2018 5calls. All rights reserved.
//

import Foundation

class FetchUserStatsOperation: BaseOperation, @unchecked Sendable {
    
    class TokenExpiredError : Error { }
    
    var userStats: UserStats?
    var firstCallTime: Date?
    var httpResponse: HTTPURLResponse?
    var error: Error?
    
    private var retryCount = 0
    
    // We’re keeping this so the code compiles, but it won’t be used anymore
    var url: URL {
        return URL(string: "")!
    }
    
    override func execute() {
        // Skip making the API request entirely
        print("FetchUserStatsOperation skipped – no API call made.")
        self.finish()
    }
    
    // Keeping parseResponse here just in case something else references it,
    // but it will never be called now.
    private func parseResponse(data: Data) throws {
        guard let statsDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
            print("Couldn't parse JSON data.")
            return
        }

        userStats = UserStats(dictionary: statsDictionary as JSONDictionary)

        if let firstCallUnixSeconds = statsDictionary["firstCallTime"] as? Double {
            firstCallTime = Date(timeIntervalSince1970: firstCallUnixSeconds)
        }
    }
}
