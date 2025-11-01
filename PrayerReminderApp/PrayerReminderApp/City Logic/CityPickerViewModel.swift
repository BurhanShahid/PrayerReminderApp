//
//  CityPickerViewModel.swift
//  PrayerReminderApp
//
//

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
final class CityPickerViewModel: NSObject, ObservableObject {
    @Published var query: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let completer: MKLocalSearchCompleter
    private var debounceTask: Task<Void, Never>?

    override init() {
        let c = MKLocalSearchCompleter()
        c.resultTypes = [.address, .pointOfInterest]
        c.region = MKCoordinateRegion(.world)
        self.completer = c

        super.init()
        self.completer.delegate = self
    }

    func updateQuery(_ text: String) {
        query = text
        debounceTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            errorMessage = nil
            isLoading = false
            completer.queryFragment = ""
            return
        }

        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard let self, !Task.isCancelled else { return }
            self.errorMessage = nil
            self.completer.queryFragment = trimmed
        }
    }

    func resolve(completion: MKLocalSearchCompletion) async -> City? {
        // Defensive: avoid resolving when titles are empty (can happen with transient states)
        guard !completion.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                errorMessage = "No details found for selection."
                return nil
            }
            let placemark = item.placemark
            let coord = placemark.coordinate

            let name = placemark.locality ?? placemark.name ?? ""
            let admin = placemark.administrativeArea ?? placemark.subAdministrativeArea
            let country = placemark.country ?? placemark.countryCode ?? "Unknown"

            guard !name.isEmpty else {
                errorMessage = "Could not determine city name."
                return nil
            }

            return City(
                name: name,
                country: country,
                admin: admin,
                latitude: coord.latitude,
                longitude: coord.longitude
            )
        } catch {
            let nsError = error as NSError
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }
            errorMessage = nsError.localizedDescription
            return nil
        }
    }
}

extension CityPickerViewModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.suggestions = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            if self.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.errorMessage = nil
            } else {
                self.errorMessage = (error as NSError).localizedDescription
            }
        }
    }
}
