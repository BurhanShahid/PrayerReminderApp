//
//  PrayerReminderAppApp.swift
//  PrayerReminderApp
//
//

import SwiftUI

@main
struct PrayerReminderAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let schedule = PrayerSchedule(from: samplePrayers, calendar: .current)

                    let granted = (try? await NotificationsManager.requestAuthorizationIfNeeded()) ?? false
                    if granted {
                        await NotificationsManager.scheduleToday(from: schedule)
                    }
                }
        }
    }
}
