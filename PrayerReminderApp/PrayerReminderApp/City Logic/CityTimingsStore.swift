//
//  CityTimingsStore.swift
//  PrayerReminderApp
//
//

import Foundation

struct StoredTimingsLegacy: Codable, Equatable {
    let city: City
    let items: [String: String] // "Fajr": "06:00", etc. 24h "HH:mm"
    let lastUpdated: Date
}

protocol CityTimingsStoringLegacy {
    func load() -> StoredTimingsLegacy?
    func save(_ data: StoredTimingsLegacy)
    func clear()
}

final class CityTimingsStoreLegacy: CityTimingsStoringLegacy {
    private let defaults: UserDefaults
    private let key = "storedCityTimingsLegacy"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> StoredTimingsLegacy? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StoredTimingsLegacy.self, from: data)
    }

    func save(_ data: StoredTimingsLegacy) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

extension StoredTimingsLegacy {
    func isFresh(for city: City, calendar: Calendar = .current) -> Bool {
        guard city == self.city else { return false }
        return calendar.isDate(lastUpdated, inSameDayAs: Date())
    }
}
