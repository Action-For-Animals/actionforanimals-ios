//
//  FetchAnimalPolicyOperation.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/31/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation

class FetchAnimalPolicyOperation: BaseOperation, @unchecked Sendable {

    // Output properties.
    // Once the job has finished consumers can check one or more of these for values.
    var httpResponse: HTTPURLResponse?
    var error: Error?
    var issuesList: [AnimalPolicy]?

    // Location parameters for geographic filtering
    private let city: String?
    private let state: String?
    private let county: String?

    init(city: String? = nil, state: String? = nil, county: String? = nil, config: URLSessionConfiguration? = nil) {
        self.city = city
        self.state = state
        self.county = county
        super.init()
        

        if let config {
            self.session = URLSession(configuration: config)
        }
    }
    
    var url: URL {
        var urlComponents = URLComponents(string: "https://getissues-wv7gpk3bya-uc.a.run.app")!
        var queryItems: [URLQueryItem] = []

        // Add location parameters for geographic filtering
        if let state = state {
            queryItems.append(URLQueryItem(name: "state", value: state))
        }
        if let county = county {
            queryItems.append(URLQueryItem(name: "county", value: county))
        }
        if let city = city {
            queryItems.append(URLQueryItem(name: "city", value: city))
        }

        // Add calling group if it exists
        if let callingGroup = UserDefaults.standard.string(forKey: UserDefaultsKey.callingGroup.rawValue),
           !callingGroup.isEmpty {
            queryItems.append(URLQueryItem(name: "group", value: callingGroup))
        }

        urlComponents.queryItems = queryItems
        let finalURL = urlComponents.url!
        return finalURL
    }

    override func execute() {
        let request = buildRequest(forURL: url)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let e = error {
                print("Error fetching issues: \(e.localizedDescription)")
                self.error = e
            } else {
                self.handleResponse(data: data, response: response)
            }
            
            self.finish()
        }

        task.resume()
    }
    
    private func handleResponse(data: Data?, response: URLResponse?) {
        guard let data = data else {
            print("data was nil, ignoring response")
            return
        }
        guard let http = response as? HTTPURLResponse else {
            print("Response was not an HTTP URL response (or was nil), ignoring")
            return
        }
        
        httpResponse = http
        
        if http.statusCode == 200 {
            do {
                self.issuesList = try parseIssues(data: data)
            } catch let e {
                print("Error parsing issues: \(e.localizedDescription)")
            }
        } else {
            print("Received HTTP \(http.statusCode)")
        }
    }
    
    private func parseIssues(data: Data) throws -> [AnimalPolicy] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AnimalPolicy].self, from: data)
    }
}
