// NotificationsManager.swift
// PrayerReminderApp

import Foundation
import UserNotifications

enum NotificationsManager {
    static func requestAuthorizationIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        case .denied:
            return false
        case .authorized, .provisional, .ephemeral:
            return true
        @unknown default:
            return false
        }
    }

    static func scheduleToday(from schedule: PrayerSchedule, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()

        // Clear previously scheduled prayer notifications to avoid duplicates
        await center.removeAllPendingNotificationRequests()

        // Build a list of (name, date) including Sunrise
        let names = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
        var entries: [(String, Date)] = []
        for name in names {
            if let date = schedule.date(for: name) {
                entries.append((name, date))
            }
        }

        // Only schedule those still in the future today
        let upcoming = entries.filter { $0.1 > now }

        for (name, date) in upcoming {
            let comps = schedule.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

            let content = UNMutableNotificationContent()
            content.title = name == "Sunrise" ? "Sunrise" : "\(name) time"
            content.body = name == "Sunrise" ? "It's sunrise time." : "It's time for \(name)."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "prayer.\(name).\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)",
                                                content: content,
                                                trigger: trigger)
            do {
                try await center.add(request)
            } catch {

            }
        }
    }
}

private extension UNUserNotificationCenter {
    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func removeAllPendingNotificationRequests() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            removeAllPendingNotificationRequests()
            continuation.resume()
        }
    }
}
