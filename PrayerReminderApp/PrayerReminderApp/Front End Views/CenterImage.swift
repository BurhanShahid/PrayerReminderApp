//
//  CenterImage.swift
//  PrayerReminderApp
//
//

import SwiftUI

struct CenterImage: View {
    let currentPrayerName: String
    let nextPrayerName: String
    let nextPrayerTimeRemaining: String

    private func accentColor(for name: String) -> Color {
        switch name.lowercased() {
        case "fajr", "maghrib":
            return .orange
        case "dhuhr", "asr", "sunrise":
            return .yellow
        case "isha":
            return .indigo
        default:
            return .orange
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: imageForPrayer(currentPrayerName))
                .font(.system(size: 58))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(accentColor(for: currentPrayerName).opacity(0.95))

            Text("Next Prayer: \(nextPrayerName)")
                .font(.title2)
                .fontWeight(.semibold)

            if nextPrayerName.lowercased() != "none" {
                Text(nextPrayerTimeRemaining)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 40)
    }
}

#Preview {
    CenterImage(
        currentPrayerName: "Isha",
        nextPrayerName: "Dhuhr",
        nextPrayerTimeRemaining: "in 2 hours 15 minutes"
    )
    .padding()
}
