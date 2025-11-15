//
//  LeagueOperations.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-06.
//

import Foundation

// MARK: - Join Monthly League Operation
class JoinMonthlyLeagueOperation: BaseOperation, @unchecked Sendable {

    // Input properties
    var userProfile: UserProfile
    var animalsHelpedThisMonth: Int
    var city: String?
    var state: String?

    // Output properties
    var httpResponse: HTTPURLResponse?
    var error: Error?
    var success: Bool = false
    var alreadyMember: Bool = false

    init(userProfile: UserProfile, animalsHelpedThisMonth: Int, city: String? = nil, state: String? = nil) {
        self.userProfile = userProfile
        self.animalsHelpedThisMonth = animalsHelpedThisMonth
        self.city = city
        self.state = state
    }

    var url: URL {
        return URL(string: "https://joinmonthlyLeague-wv7gpk3bya-uc.a.run.app")!
    }

    override func execute() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        var request = buildRequest(forURL: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body with only league-relevant data
        var requestBody: [String: Any] = [
            "callerid": AnalyticsManager.shared.callerID,
            "nickname": userProfile.nickname ?? userProfile.firstName ?? "",
            "avatar": userProfile.avatarIconName,
            "animalsHelped": animalsHelpedThisMonth
        ]

        // Add location if available
        if let city = city, !city.isEmpty, let state = state, !state.isEmpty {
            requestBody["location"] = "\(city), \(state)"
        }

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
                print("JoinMonthlyLeague network error: \(e)")
            } else {
                let http = response as! HTTPURLResponse
                self.httpResponse = http

                if http.statusCode == 200 {
                    self.success = true
                    print("JoinMonthlyLeague succeeded")

                    // Store that user joined league this month (using UTC to match backend)
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = TimeZone(identifier: "UTC")!
                    let now = Date()
                    let currentMonthKey = String(format: "%04d-%02d",
                                               calendar.component(.year, from: now),
                                               calendar.component(.month, from: now))
                    UserDefaults.standard.set(currentMonthKey, forKey: UserDefaultsKey.lastLeagueMonth.rawValue)
                    print("Stored league participation for month: \(currentMonthKey)")

                    // Parse response
                    if let data = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                self.alreadyMember = json["alreadyMember"] as? Bool ?? false
                                print("JoinMonthlyLeague response: \(json)")
                            }
                        } catch {
                            print("Failed to parse JoinMonthlyLeague response JSON: \(error)")
                        }
                    }
                } else {
                    print("JoinMonthlyLeague failed with status: \(http.statusCode)")
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

// MARK: - Fetch Current Month Leaderboard Operation
class FetchCurrentMonthLeaderboardOperation: BaseOperation, @unchecked Sendable {

    // Output properties
    var httpResponse: HTTPURLResponse?
    var error: Error?
    var currentLeaderboard: [LeagueParticipant] = []
    var currentMeta: LeagueMeta?

    var url: URL {
        return URL(string: "https://getcurrentmonthleaderboard-wv7gpk3bya-uc.a.run.app")!
    }

    override func execute() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        var request = buildRequest(forURL: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { (data, response, error) in
            if let e = error {
                self.error = e
                print("FetchCurrentMonthLeaderboard network error: \(e)")
            } else {
                let http = response as! HTTPURLResponse
                self.httpResponse = http

                if http.statusCode == 200, let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                        self.currentMeta = LeagueMeta(
                            totalAnimals: json?["totalAnimals"] as? Int ?? 0,
                            participantCount: json?["participantCount"] as? Int ?? 0,
                            month: json?["month"] as? String
                        )

                        if let participants = json?["participants"] as? [[String: Any]] {
                            self.currentLeaderboard = participants.compactMap { participantData in
                                guard let callerid = participantData["callerid"] as? String,
                                      let nickname = participantData["nickname"] as? String,
                                      let avatar = participantData["avatar"] as? String,
                                      let animalsHelped = participantData["animalsHelped"] as? Int,
                                      let rank = participantData["rank"] as? Int else {
                                    return nil
                                }
                                return LeagueParticipant(
                                    callerid: callerid,
                                    nickname: nickname,
                                    location: participantData["location"] as? String,
                                    avatar: avatar,
                                    animalsHelped: animalsHelped,
                                    rank: rank
                                )
                            }
                        }

                        print("FetchCurrentMonthLeaderboard succeeded: \(self.currentLeaderboard.count) participants")

                    } catch {
                        print("Failed to parse FetchCurrentMonthLeaderboard response JSON: \(error)")
                        self.error = error
                    }
                } else {
                    print("FetchCurrentMonthLeaderboard failed with status: \(http.statusCode)")
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

// MARK: - Fetch Previous Month Leaderboard Operation
class FetchPreviousMonthLeaderboardOperation: BaseOperation, @unchecked Sendable {

    // Output properties
    var httpResponse: HTTPURLResponse?
    var error: Error?
    var previousLeaderboard: [LeagueParticipant] = []
    var previousMeta: LeagueMeta?

    var url: URL {
        return URL(string: "https://getpreviousmonthleaderboard-wv7gpk3bya-uc.a.run.app")!
    }

    override func execute() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        var request = buildRequest(forURL: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { (data, response, error) in
            if let e = error {
                self.error = e
                print("FetchPreviousMonthLeaderboard network error: \(e)")
            } else {
                let http = response as! HTTPURLResponse
                self.httpResponse = http

                if http.statusCode == 200, let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                        self.previousMeta = LeagueMeta(
                            totalAnimals: json?["totalAnimals"] as? Int ?? 0,
                            participantCount: json?["participantCount"] as? Int ?? 0,
                            month: json?["month"] as? String
                        )

                        if let participants = json?["participants"] as? [[String: Any]] {
                            self.previousLeaderboard = participants.compactMap { participantData in
                                guard let callerid = participantData["callerid"] as? String,
                                      let nickname = participantData["nickname"] as? String,
                                      let avatar = participantData["avatar"] as? String,
                                      let animalsHelped = participantData["animalsHelped"] as? Int,
                                      let rank = participantData["rank"] as? Int else {
                                    return nil
                                }
                                return LeagueParticipant(
                                    callerid: callerid,
                                    nickname: nickname,
                                    location: participantData["location"] as? String,
                                    avatar: avatar,
                                    animalsHelped: animalsHelped,
                                    rank: rank
                                )
                            }
                        }

                        print("FetchPreviousMonthLeaderboard succeeded: \(self.previousLeaderboard.count) participants")

                    } catch {
                        print("Failed to parse FetchPreviousMonthLeaderboard response JSON: \(error)")
                        self.error = error
                    }
                } else {
                    print("FetchPreviousMonthLeaderboard failed with status: \(http.statusCode)")
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

