//
//  CityPickerView.swift
//  PrayerReminderApp
//
//

import SwiftUI
import MapKit

struct CityPickerView: View {
    // Now returns a full City struct
    @Binding var selectedCity: City?
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = CityPickerViewModel()
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.suggestions.isEmpty {
                    ProgressView("Searching…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        if let error = viewModel.errorMessage {
                            Section {
                                Text(error)
                                    .foregroundColor(.red)
                            }
                        }

                        Section {
                            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                Button {
                                    Task {
                                        if let city = await viewModel.resolve(completion: suggestion) {
                                            selectedCity = city
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(primaryTitle(for: suggestion))
                                                .font(.headline)
                                            if let subtitle = subtitle(for: suggestion), !subtitle.isEmpty {
                                                Text(subtitle)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if let sel = selectedCity, matches(suggestion, selected: sel) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose City")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { _, newValue in
                viewModel.updateQuery(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                // Seed an initial query to show examples
                if searchText.isEmpty {
                    searchText = "San"
                    viewModel.updateQuery("San")
                }
            }
        }
    }

    private func primaryTitle(for item: MKLocalSearchCompletion) -> String {
        item.title
    }

    private func subtitle(for item: MKLocalSearchCompletion) -> String? {
        item.subtitle.isEmpty ? nil : item.subtitle
    }

    private func matches(_ completion: MKLocalSearchCompletion, selected: City) -> Bool {
        let titleMatches = completion.title.caseInsensitiveCompare(selected.name) == .orderedSame
        let subtitle = completion.subtitle.lowercased()
        let countryMatches = subtitle.contains(selected.country.lowercased())
        let adminMatches = selected.admin.map { subtitle.contains($0.lowercased()) } ?? false
        return titleMatches && (countryMatches || adminMatches)
    }
}

#Preview {
    CityPickerView(selectedCity: .constant(
        City(name: "Irvine", country: "United States", admin: "California", latitude: 33.6846, longitude: -117.8265)
    ))
}
