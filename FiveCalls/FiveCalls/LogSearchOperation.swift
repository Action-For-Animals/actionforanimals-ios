//
//  LogSearchOperation.swift
//  FiveCalls
//
//  Created by Nick O'Neill on 6/22/25.
//  Copyright © 2025 5calls. All rights reserved.
//

import Foundation

class LogSearchOperation: BaseOperation, @unchecked Sendable {
    var searchQuery: String
    
    var httpResponse: HTTPURLResponse?
    var error: Error?
    
    init(searchQuery: String) {
        self.searchQuery = searchQuery
    }
    
    var url: URL {
        return URL(string: "temp")!
    }

    override func execute() {
        // Do nothing and finish immediately
        print("LogSearchOperation skipped — no data sent.")
        self.finish()
    }
}
