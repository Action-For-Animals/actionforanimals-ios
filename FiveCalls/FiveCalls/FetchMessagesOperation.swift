//
//  FetchMessagesOperation.swift
//  FiveCalls
//
//  Created by Nick O'Neill on 3/17/24.
//  Copyright © 2024 5calls. All rights reserved.
//

import Foundation

class FetchMessagesOperation: BaseOperation, @unchecked Sendable {
    var district: String
    
    var error: Error?
    var httpResponse: HTTPURLResponse?
    var messages: [InboxMessage]?

    init(district: String, config: URLSessionConfiguration? = nil) {
        self.district = district

        super.init()
        if let config {
            self.session = URLSession(configuration: config)
        }
    }
    
    var url: URL {
        // Not used anymore
        return URL(string: "temp")!
    }
    
    override func execute() {
        // Skip network call, return empty messages immediately
        self.messages = []
        self.finish()
    }
}
