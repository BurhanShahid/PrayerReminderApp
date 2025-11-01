//
//  TopLabel.swift
//  PrayerReminderApp
//
//

import SwiftUI

struct TopLabel: View {
    let cityCountry: String
    var onTapCity: (() -> Void)? = nil

    @Environment(\.prayerDateFormatterTimeZone) private var tz

    var body: some View {
        VStack(spacing: 6) {
            Text("Prayer Timings")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, -15)

            HStack(spacing: 8) {
                Text(todayDate(timeZone: tz))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("•")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Group {
                    if let onTapCity {
                        Button(action: onTapCity) {
                            Text(cityCountry)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change City")
                    } else {
                        Text(cityCountry)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    TopLabel(cityCountry: "New York, United States", onTapCity: {})
        .padding()
}

