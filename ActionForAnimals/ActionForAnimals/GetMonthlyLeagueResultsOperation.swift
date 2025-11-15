//
//  GetMonthlyLeagueResultsOperation.swift
//  ActionForAnimals
//
//  Created by Claude on 2024-11-12.
//

import Foundation

class GetMonthlyLeagueResultsOperation: BaseOperation, @unchecked Sendable {

    // Input properties
    var monthKey: String

    // Output properties
    var httpResponse: HTTPURLResponse?
    var error: Error?
    var success: Bool = false
    var monthTransitionData: MonthTransitionData?

    init(monthKey: String) {
        self.monthKey = monthKey
    }

    var url: URL {
        return URL(string: "https://getmonthlyLeagueResults-wv7gpk3bya-uc.a.run.app")!
    }

    override func execute() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        var request = buildRequest(forURL: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        let requestBody: [String: Any] = [
            "callerid": AnalyticsManager.shared.callerID,
            "monthKey": monthKey
        ]

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
                print("GetMonthlyLeagueResults network error: \(e)")
            } else {
                let http = response as! HTTPURLResponse
                self.httpResponse = http

                if http.statusCode == 200 {
                    self.success = true
                    print("GetMonthlyLeagueResults succeeded")

                    // Parse response
                    if let data = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                self.monthTransitionData = self.parseMonthTransitionData(from: json)
                                print("GetMonthlyLeagueResults response parsed successfully")
                            }
                        } catch {
                            print("Failed to parse GetMonthlyLeagueResults response JSON: \(error)")
                            self.error = error
                        }
                    }
                } else {
                    print("GetMonthlyLeagueResults failed with status: \(http.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Error response: \(responseString)")
                    }
                }
            }
            self.finish()
        }
        task.resume()
    }

    private func parseMonthTransitionData(from json: [String: Any]) -> MonthTransitionData? {
        guard let month = json["month"] as? String,
              let totalAnimals = json["totalAnimals"] as? Int,
              let totalParticipants = json["totalParticipants"] as? Int else {
            print("Missing required fields in response")
            return nil
        }

        // Parse winners
        var winners: [MonthTransitionData.Winner] = []
        if let winnersArray = json["winners"] as? [[String: Any]] {
            for winnerData in winnersArray {
                if let rank = winnerData["rank"] as? Int,
                   let nickname = winnerData["nickname"] as? String,
                   let animalsHelped = winnerData["animalsHelped"] as? Int,
                   let avatar = winnerData["avatar"] as? String {
                    winners.append(MonthTransitionData.Winner(
                        rank: rank,
                        nickname: nickname,
                        animalsHelped: animalsHelped,
                        avatar: avatar
                    ))
                }
            }
        }

        // Parse user stats
        var userStats: MonthTransitionData.UserStats? = nil
        if let userStatsData = json["userStats"] as? [String: Any],
           let rank = userStatsData["rank"] as? Int,
           let animalsHelped = userStatsData["animalsHelped"] as? Int,
           let totalParticipants = userStatsData["totalParticipants"] as? Int {
            userStats = MonthTransitionData.UserStats(
                rank: rank,
                animalsHelped: animalsHelped,
                totalParticipants: totalParticipants
            )
        }

        return MonthTransitionData(
            month: month,
            totalAnimals: totalAnimals,
            totalParticipants: totalParticipants,
            winners: winners,
            userStats: userStats
        )
    }
}