//
//  SaveUserInfoOperation.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import Foundation

class SaveUserInfoOperation: BaseOperation, @unchecked Sendable {

    // Input properties
    var userProfile: UserProfile

    // Output properties
    var httpResponse: HTTPURLResponse?
    var error: Error?
    var success: Bool = false

    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }

    var url: URL {
        return URL(string: "https://saveuserinfo-wv7gpk3bya-uc.a.run.app")!
    }

    override func execute() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        var request = buildRequest(forURL: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        var requestBody: [String: Any] = [
            "callerid": AnalyticsManager.shared.callerID
        ]

        // Add profile fields (including empty strings to clear fields)
        requestBody["firstName"] = userProfile.firstName ?? ""
        requestBody["lastName"] = userProfile.lastName ?? ""
        requestBody["nickname"] = userProfile.nickname ?? ""
        requestBody["email"] = userProfile.email ?? ""
        requestBody["avatar"] = userProfile.avatar ?? ""

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON body: \(error)")
            self.error = error
            self.finish()
            return
        }

        let task = session.dataTask(with: request) { (data, response, error) in
            if let e = error {
                self.error = e
                print("SaveUserInfo network error: \(e)")
            } else {
                let http = response as! HTTPURLResponse
                self.httpResponse = http

                if http.statusCode == 200 {
                    self.success = true
                } else {
                    print("SaveUserInfo failed with status: \(http.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Error response: \(responseString)")
                    }
                }
            }
            self.finish()
        }
        task.resume()
    }
}