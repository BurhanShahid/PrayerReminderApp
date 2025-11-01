//
//  City.swift
//  PrayerReminderApp
//
//

import Foundation
import CoreLocation

struct City: Identifiable, Codable, Equatable {
    var id: String { "\(name)|\(admin ?? "")|\(country)|\(latitude)|\(longitude)" }

    let name: String
    let country: String
    let admin: String?
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    var displayName: String {
        if let admin, !admin.isEmpty, admin != name {
            return "\(name), \(admin), \(country)"
        } else {
            return "\(name), \(country)"
        }
    }
}
