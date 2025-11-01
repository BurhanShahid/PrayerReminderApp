//
//  ContentView.swift
//  PrayerReminderApp
//
//

import SwiftUI

struct ContentView: View {
    @StateObject private var timeProvider: TimeProvider = TimeProvider()
    @StateObject private var timings: TimingsManager = TimingsManager()
    @AppStorage("selectedCityDataBase64") private var selectedCityDataBase64: String = ""
    @State private var selectedCity: City? = nil

    @State private var showingCityPicker = false

    var body: some View {
        Group {
            // Derive calendar and timezone in a single expression
            let calAndTZ: (Calendar, TimeZone?) = {
                var c = Calendar.current
                var tzOpt: TimeZone? = nil
                if let tzId = timings.timeZoneIdentifier, let tz = TimeZone(identifier: tzId) {
                    c.timeZone = tz
                    tzOpt = tz
                }
                return (c, tzOpt)
            }()
            let cal = calAndTZ.0
            let cityTimeZone = calAndTZ.1

            let prayersToUse = timings.prayers.isEmpty ? samplePrayers : timings.prayers
            let schedule = PrayerSchedule(from: prayersToUse, calendar: cal)
            let evaluation = evaluate(now: timeProvider.now, schedule: schedule)

            ZStack {
                BackgroundView(currentPrayerName: evaluation.backgroundPrayerName)

                VStack {
                    TopLabel(
                        cityCountry: selectedCity?.displayName ?? "Choose City",
                        onTapCity: { showingCityPicker = true }
                    )
                    .environment(\.prayerDateFormatterTimeZone, cityTimeZone) // provide TZ via environment

                    Spacer()

                    CenterImage(
                        currentPrayerName: evaluation.centerSymbolPrayerName,
                        nextPrayerName: evaluation.nextPrayerName,
                        nextPrayerTimeRemaining: evaluation.nextPrayerTimeRemainingText
                    )

                    Spacer()

                    PrayerList(
                        prayers: prayersToUse,
                        currentPrayerName: evaluation.highlightedPrayerName ?? evaluation.centerSymbolPrayerName
                    )
                }
                .padding(15)
            }
        }
        .sheet(isPresented: $showingCityPicker) {
            CityPickerView(selectedCity: Binding(
                get: { selectedCity },
                set: { newCity in
                    selectedCity = newCity
                    persistSelectedCity()
                    Task { await fetchIfPossible() }
                }
            ))
        }
        .onAppear {
            loadPersistedCity()
            Task { await fetchIfPossible() }
        }
    }

    private func fetchIfPossible() async {
        guard let city = selectedCity else { return }
        await timings.getTodayTimings(for: city)
    }

    private func persistSelectedCity() {
        guard let city = selectedCity else {
            selectedCityDataBase64 = ""
            return
        }
        if let data = try? JSONEncoder().encode(city) {
            selectedCityDataBase64 = data.base64EncodedString()
        }
    }

    private func loadPersistedCity() {
        guard !selectedCityDataBase64.isEmpty,
              let data = Data(base64Encoded: selectedCityDataBase64),
              let city = try? JSONDecoder().decode(City.self, from: data) else {
            return
        }
        selectedCity = city
    }
}

private struct PrayerDateFormatterTimeZoneKey: EnvironmentKey {
    static let defaultValue: TimeZone? = nil
}

extension EnvironmentValues {
    var prayerDateFormatterTimeZone: TimeZone? {
        get { self[PrayerDateFormatterTimeZoneKey.self] }
        set { self[PrayerDateFormatterTimeZoneKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}

