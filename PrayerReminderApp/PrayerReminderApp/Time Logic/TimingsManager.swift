//
//  TimingsManager.swift
//  PrayerReminderApp
//
//

import Foundation
import Combine

@MainActor
final class TimingsManager: ObservableObject {
    @Published private(set) var prayers: [Prayer] = []
    @Published private(set) var timeZoneIdentifier: String?

    private let store: CityTimingsStoringLegacy
    private let api: PrayerTimingsFetching
    private let calendar: Calendar

    init(store: CityTimingsStoringLegacy = CityTimingsStoreLegacy(),
         api: PrayerTimingsFetching = PrayerTimingsAPI(),
         calendar: Calendar = .current) {
        self.store = store
        self.api = api
        self.calendar = calendar
    }

    func getTodayTimings(for city: City) async {

        if let cached = store.load(), cached.isFresh(for: city, calendar: calendar) {
            self.prayers = Self.makePrayers(from: cached.items)
            self.timeZoneIdentifier = nil
            return
        }

        // Fetch new
        do {
            let response = try await api.fetchTimings(for: city, on: Date())
            let required = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
            let hasAll = required.allSatisfy { response.items.keys.contains($0) }
            guard hasAll else {
                self.prayers = Self.makePrayers(from: response.items)
                self.timeZoneIdentifier = response.timeZoneIdentifier
                return
            }

            let stored = StoredTimingsLegacy(city: city, items: response.items, lastUpdated: Date())
            store.save(stored)

            self.prayers = Self.makePrayers(from: response.items)
            self.timeZoneIdentifier = response.timeZoneIdentifier
        } catch {
            if let cached = store.load() {
                self.prayers = Self.makePrayers(from: cached.items)
                // No timezone available from legacy cache
                self.timeZoneIdentifier = nil
            }
        }
    }

    static func makePrayers(from dict: [String: String]) -> [Prayer] {
        let order = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
        return order.map { name in
            let time = dict[name] ?? "--:--"
            return Prayer(prayerName: name, prayerTime: time, isPassed: false)
        }
    }

    func clearCache() {
        store.clear()
    }
}

