//
//  FetchContactsOperation.swift
//  ActionForAnimals
//
//  Created by Ben Scheirman on 1/9/19.
//  Copyright © 2019 5calls. All rights reserved.
//

import Foundation
import OneSignal
import FirebaseFunctions
import FirebaseAppCheck

class FetchContactsOperation: BaseOperation, @unchecked Sendable {

    var location: UserLocation

    var httpResponse: HTTPURLResponse?
    var error: Error?
    var contacts: [Contact]?
    var splitDistrict: Bool?
    var district: String?
    var lowAccuracyMessage: String?

    // Location metadata for campaign filtering
    var city: String?
    var county: String?
    var state: String?

    init(location: UserLocation, config: URLSessionConfiguration? = nil) {
        self.location = location

        super.init()
        if let config {
            self.session = URLSession(configuration: config)
        }
    }
    

    override func execute() {
        executeWithFirebaseSDK()
    }

    private func executeWithFirebaseSDK() {
        let functions = Functions.functions()
        let getOfficials = functions.httpsCallable("getOfficialsCallable")

        // Prepare parameters based on location type
        var parameters: [String: Any] = [:]

        switch location.locationType {
        case .coordinates:
            let coords = location.locationValue.split(separator: ",")
            if coords.count == 2 {
                parameters["lat"] = String(coords[0])
                parameters["lon"] = String(coords[1])
            }
        case .address:
            let trimmedValue = location.locationValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedValue.range(of: "^\\d{5}$", options: .regularExpression) != nil ||
               trimmedValue.range(of: "^\\d{5}-\\d{4}$", options: .regularExpression) != nil {
                parameters["zipcode"] = trimmedValue
            } else {
                parameters["address"] = location.locationValue
            }
        }

        getOfficials.call(parameters) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.error = error
                self.finish()
                return
            }

            guard let data = result?.data as? [String: Any] else {
                self.error = NSError(domain: "FetchContactsOperation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                self.finish()
                return
            }

            self.handleFirebaseResponse(data: data)
            self.finish()
        }
    }

    private func handleFirebaseResponse(data: [String: Any]) {
        do {
            // Convert the response back to our expected format
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            self.contacts = try parseContacts(data: jsonData)
        } catch {
            self.error = error
        }
    }
    
    private func handleResponse(data: Data?, response: URLResponse?) {
        guard let data = data else { return }
        guard let http = response as? HTTPURLResponse else { return }
        
        print("HTTP \(http.statusCode)")
        httpResponse = http
        
        if http.statusCode == 200 {
            do {
                self.contacts = try parseContacts(data: data)
            } catch let e {
                print("Error parsing reps: \(e.localizedDescription)")
            }
        } else {
            print("Received HTTP \(http.statusCode)")
        }
    }
    
    private func parseContacts(data: Data) throws -> [Contact] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let contactList = try decoder.decode(ContactList.self, from: data)

        splitDistrict = contactList.isSplit
        if contactList.generalizedLocationID != "-" {
            district = contactList.generalizedLocationID
            OneSignal.sendTag("districtID", value: contactList.generalizedLocationID)
        }

        // Handle low accuracy message
        if contactList.lowAccuracy == true && contactList.message != nil {
            lowAccuracyMessage = contactList.message
        }

        // Store location metadata for campaign filtering
        city = contactList.location
        county = contactList.county
        state = contactList.state

        return contactList.representatives
    }
}

