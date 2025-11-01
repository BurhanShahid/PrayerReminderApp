//
//  SampleData.swift
//  PrayerReminderApp
//
//

import Foundation
import SwiftUI

struct Prayer {
    let prayerName: String
    let prayerTime: String
    let isPassed: Bool
}

let samplePrayers = [
    Prayer(prayerName: "Fajr",    prayerTime: "06:00", isPassed: false),
    Prayer(prayerName: "Sunrise", prayerTime: "07:10", isPassed: false),
    Prayer(prayerName: "Dhuhr",   prayerTime: "12:35", isPassed: false),
    Prayer(prayerName: "Asr",     prayerTime: "15:36", isPassed: false),
    Prayer(prayerName: "Maghrib", prayerTime: "17:59", isPassed: false),
    Prayer(prayerName: "Isha",    prayerTime: "19:10", isPassed: false)
]

func imageForPrayer(_ name: String) -> String {
    switch name.lowercased() {
    case "fajr": return "sunrise.fill"
    case "dhuhr": return "sun.max.fill"
    case "asr": return "sun.horizon.fill"
    case "maghrib": return "sunset.fill"
    case "isha": return "moon.stars.fill"
    default: return "sun.horizon.fill"
    }
}

func todayDate(timeZone: TimeZone? = nil) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    if let tz = timeZone {
        formatter.timeZone = tz
    }
    return formatter.string(from: Date())
}

func backgroundGradient(for prayerName: String) -> [Color] {
    switch prayerName.lowercased() {
    case "fajr":
        return [.orange.opacity(0.35), .pink.opacity(0.2)]
    case "sunrise":
        return [.yellow.opacity(0.25), .orange.opacity(0.12)]
    case "dhuhr", "asr":
        return [.blue.opacity(0.15), .cyan.opacity(0.1)]
    case "maghrib":
        return [.orange.opacity(0.35), .purple.opacity(0.15)]
    case "isha":
        return [
            Color.indigo.opacity(0.17),
            Color.black.opacity(0.32)
        ]
    default:
        return [
            Color.gray.opacity(0.20),
            Color.black.opacity(0.3)
        ]
    }
}

