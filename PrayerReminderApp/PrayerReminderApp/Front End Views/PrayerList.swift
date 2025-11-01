//
//  PrayerList.swift
//  PrayerReminderApp
//
//

import SwiftUI

struct PrayerList: View {
    let prayers: [Prayer]
    let currentPrayerName: String

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

    //Isha Icon Case
    private func symbolBaselineOffset(for name: String) -> CGFloat {
        switch name.lowercased() {
        case "isha":
            return -1
        default:
            return 0
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(prayers.indices, id: \.self) { index in
                let prayer = prayers[index]
                let isCurrent = prayer.prayerName.lowercased() == currentPrayerName.lowercased()
                let color = accentColor(for: prayer.prayerName)

                HStack(alignment: .center, spacing: 12) {
                    // Give the icon a square box to normalize vertical alignment
                    Image(systemName: imageForPrayer(prayer.prayerName))
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isCurrent ? color : color.opacity(0.95))
                        .frame(width: 28, height: 28, alignment: .center)
                        .baselineOffset(symbolBaselineOffset(for: prayer.prayerName))

                    Text(prayer.prayerName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer(minLength: 12)

                    Text(prayer.prayerTime)
                        .font(.headline)
                        .foregroundColor(isCurrent ? .primary.opacity(0.85) : .secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(
                    // Subtle background highlight for the current prayer row
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isCurrent ? color.opacity(0.10) : Color.clear)
                )

                if index < prayers.count - 1 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                        .overlay(
                            (isCurrent
                             ? Rectangle()
                                .stroke(style: StrokeStyle(lineWidth: 0.5))
                                .foregroundColor(.gray.opacity(0.65))
                             : Rectangle()
                                .stroke(style: StrokeStyle(lineWidth: 0.5))
                                .foregroundColor(.gray.opacity(0.5)))
                        )
                        .padding(.horizontal, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .padding(.top, 30)
    }
}

#Preview {
    PrayerList(
        prayers: samplePrayers,
        currentPrayerName: "Fajr"
    )
    .padding()
}

