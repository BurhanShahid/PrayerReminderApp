//
//  SunriseLogic.swift
//  PrayerReminderApp
//
//

import Foundation

struct Evaluation {
    let backgroundPrayerName: String
    let centerSymbolPrayerName: String
    let highlightedPrayerName: String?
    let nextPrayerName: String
    let nextPrayerTimeRemainingText: String
}

struct PrayerSchedule {
    let calendar: Calendar
    let items: [String: Date]

    init(from prayers: [Prayer], calendar: Calendar) {
        self.calendar = calendar
        var dict: [String: Date] = [:]
        for p in prayers {
            if let date = PrayerSchedule.makeDate(todayTimeString: p.prayerTime, calendar: calendar) {
                dict[p.prayerName.capitalized] = date
            }
        }
        self.items = dict
    }

    func date(for name: String) -> Date? {
        items[name.capitalized]
    }

    func noonOfSameDay(as date: Date) -> Date {
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps) ?? date
    }

    func nextDayFajr(basedOn fajrToday: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: fajrToday) ?? fajrToday
    }

    private static func makeDate(todayTimeString: String, calendar: Calendar) -> Date? {
        let parts = todayTimeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return calendar.date(from: comps)
    }
}

func evaluate(now: Date, schedule: PrayerSchedule) -> Evaluation {
    let cal = schedule.calendar

    guard
        let fajr = schedule.date(for: "Fajr"),
        let sunrise = schedule.date(for: "Sunrise"),
        let dhuhr = schedule.date(for: "Dhuhr"),
        let asr = schedule.date(for: "Asr"),
        let maghrib = schedule.date(for: "Maghrib"),
        let isha = schedule.date(for: "Isha")
    else {
        // Fallback to Sunrise visuals, no highlight
        return Evaluation(
            backgroundPrayerName: "Sunrise",
            centerSymbolPrayerName: "Sunrise",
            highlightedPrayerName: nil,
            nextPrayerName: "Dhuhr",
            nextPrayerTimeRemainingText: ""
        )
    }

    let sunriseEnd = cal.date(byAdding: .minute, value: 20, to: sunrise) ?? sunrise
    let noon = schedule.noonOfSameDay(as: now)
    let nextDayFajr = schedule.nextDayFajr(basedOn: fajr)

    // Determine highlight
    let highlighted: String?
    if now >= sunrise && now < sunriseEnd {
        highlighted = "Sunrise"
    } else if (now >= sunriseEnd && now < dhuhr) || (now >= noon && now < nextDayFajr) {
        highlighted = nil
    } else {
        if now >= fajr && now < sunrise {
            highlighted = "Fajr"
        } else if now >= dhuhr && now < asr {
            highlighted = "Dhuhr"
        } else if now >= asr && now < maghrib {
            highlighted = "Asr"
        } else if now >= maghrib && now < isha {
            highlighted = "Maghrib"
        } else {
            if now >= isha && now < noon {
                highlighted = "Isha"
            } else {
                highlighted = nil
            }
        }
    }

    // Determine visuals for the center icon (unchanged)
    let currentForVisuals: String = {
        if now >= sunrise && now < sunriseEnd {
            return "Sunrise"
        }
        if now >= fajr && now < sunrise { return "Fajr" }
        if now >= dhuhr && now < asr { return "Dhuhr" }
        if now >= asr && now < maghrib { return "Asr" }
        if now >= maghrib && now < isha { return "Maghrib" }
        if now >= isha { return "Isha" }
        return "Isha"
    }()

    // Determine background only: after 20 minutes past Sunrise and before Dhuhr, use Dhuhr color
    let currentForBackground: String = {
        if now >= sunrise && now < sunriseEnd {
            return "Sunrise"
        }
        if now >= sunriseEnd && now < dhuhr {
            return "Dhuhr"
        }
        if now >= fajr && now < sunrise { return "Fajr" }
        if now >= dhuhr && now < asr { return "Dhuhr" }
        if now >= asr && now < maghrib { return "Asr" }
        if now >= maghrib && now < isha { return "Maghrib" }
        if now >= isha { return "Isha" }
        return "Isha"
    }()

    // Next prayer name and remaining time
    let nextNameAndDate: (String, Date)? = {
        let ordered: [(String, Date)] = [
            ("Fajr", fajr),
            ("Sunrise", sunrise),
            ("Dhuhr", dhuhr),
            ("Asr", asr),
            ("Maghrib", maghrib),
            ("Isha", isha),
            ("Fajr", nextDayFajr)
        ]

        if currentForVisuals.caseInsensitiveCompare("Sunrise") == .orderedSame {
            return ("Dhuhr", dhuhr)
        }
        return ordered.first(where: { $0.1 > now })
    }()

    let nextName = nextNameAndDate?.0 ?? "None"
    let nextRemaining = nextNameAndDate.map { remainingString(until: $0.1, from: now, calendar: cal) } ?? ""

    return Evaluation(
        backgroundPrayerName: currentForBackground,
        centerSymbolPrayerName: currentForVisuals,
        highlightedPrayerName: highlighted,
        nextPrayerName: nextName,
        nextPrayerTimeRemainingText: nextName == "None" ? "" : nextRemaining
    )
}

private func remainingString(until target: Date, from now: Date, calendar: Calendar) -> String {
    let comps = calendar.dateComponents([.hour, .minute], from: now, to: target)
    let h = comps.hour ?? 0
    let m = comps.minute ?? 0
    if h <= 0 {
        return "in \(m) minutes"
    } else if m == 0 {
        return "in \(h) hours"
    } else {
        return "in \(h) hours \(m) minutes"
    }
}
