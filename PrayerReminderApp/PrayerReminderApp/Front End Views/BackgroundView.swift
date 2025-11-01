//
//  BackgroundView.swift
//  PrayerReminderApp
//
//

import SwiftUI

struct BackgroundView: View {
    let currentPrayerName: String

    var body: some View {
        LinearGradient(
            colors: backgroundGradient(for: currentPrayerName),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView(currentPrayerName: "Fajr")
}
