//
//  TimeProvider.swift
//  PrayerReminderApp
//
//

import Foundation
import Combine

final class TimeProvider: ObservableObject {
    @Published var now: Date = Date()

    private var cancellable: AnyCancellable?

    init(every seconds: TimeInterval = 30) {
        cancellable = Timer.publish(every: seconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }

    deinit {
        cancellable?.cancel()
    }
}
