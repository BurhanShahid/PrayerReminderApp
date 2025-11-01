//
//  PrayerTimingsAPI.swift
//  PrayerReminderApp
//
//

import Foundation
import CoreLocation

struct PrayerTimingsAPIResponse: Codable {
    let items: [String: String]
    let timeZoneIdentifier: String
}

protocol PrayerTimingsFetching {
    func fetchTimings(for city: City, on date: Date) async throws -> PrayerTimingsAPIResponse
}

enum PrayerTimingsAPIError: Error {
    case invalidURL
    case badResponse
    case decodingFailed
    case missingRequiredTimes
}

final class PrayerTimingsAPI: PrayerTimingsFetching {
    private let baseURLString = "https://api.aladhan.com/v1/timingsByCity"

    //Cache
    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = .current
        return formatter
    }()

    func fetchTimings(for city: City, on date: Date) async throws -> PrayerTimingsAPIResponse {
        let formattedDate = Self.apiDateFormatter.string(from: date)

        //URL
        guard var components = URLComponents(string: "\(baseURLString)/\(formattedDate)") else {
            throw PrayerTimingsAPIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "city", value: city.name),
            URLQueryItem(name: "country", value: city.country),
            URLQueryItem(name: "method", value: "2"), // ISNA (example)
            URLQueryItem(name: "school", value: "1")  // 1 = Hanafi, 0 = Shafi
        ]

        guard let url = components.url else {
            throw PrayerTimingsAPIError.invalidURL
        }

        //Network call
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw PrayerTimingsAPIError.badResponse
        }

        let decoded: AladhanEnvelope
        do {
            decoded = try JSONDecoder().decode(AladhanEnvelope.self, from: data)
        } catch {
            throw PrayerTimingsAPIError.decodingFailed
        }

        if let code = decoded.code, code != 200 {
            throw PrayerTimingsAPIError.badResponse
        }

        let t = decoded.data.timings
        let sanitized: [String: String] = [
            "Fajr": Self.cleanTimeString(t.Fajr),
            "Sunrise": Self.cleanTimeString(t.Sunrise),
            "Dhuhr": Self.cleanTimeString(t.Dhuhr),
            "Asr": Self.cleanTimeString(t.Asr),
            "Maghrib": Self.cleanTimeString(t.Maghrib),
            "Isha": Self.cleanTimeString(t.Isha)
        ]

        let required = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
        let hhmmRegex = try! NSRegularExpression(pattern: #"^\d{2}:\d{2}$"#)
        let allPresentAndValid = required.allSatisfy { key in
            if let val = sanitized[key] {
                let range = NSRange(location: 0, length: val.utf16.count)
                return hhmmRegex.firstMatch(in: val, options: [], range: range) != nil
            }
            return false
        }
        guard allPresentAndValid else {
            throw PrayerTimingsAPIError.missingRequiredTimes
        }

        let tz = decoded.data.meta.timezone

        return PrayerTimingsAPIResponse(items: sanitized, timeZoneIdentifier: tz)
    }

    private static func cleanTimeString(_ raw: String) -> String {
        if raw.count == 5, raw[raw.index(raw.startIndex, offsetBy: 2)] == ":" {
            return String(raw.prefix(5))
        }
        let pattern = #"(\d{2}:\d{2})"#
        if let range = raw.range(of: pattern, options: .regularExpression) {
            return String(raw[range])
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


private struct AladhanEnvelope: Codable {
    let code: Int?
    let status: String?
    let data: AladhanData
}

private struct AladhanData: Codable {
    let timings: AladhanTimings
    let meta: AladhanMeta
}

private struct AladhanTimings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}

private struct AladhanMeta: Codable {
    let timezone: String
}
