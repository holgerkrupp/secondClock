//
//  SearchView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import SwiftUI
import MapKit
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var locVM: LocationManager = LocationManager.shared

    let specialTimeZones = [
        "",
        "UTC",
        "Japanese Imperial Year",
        "French Revolutionary Date",
        "French Decimal Time",
        "Discordian Date",
        "Holocene Date",
        "Maya Long Count",
        "ISO Week Date",
        "Ordinal Date",
        "Julian Date",
        "Modified Julian Date",
        "Mars Time",
        "Greenwich Sidereal Time",
        ".beat",
        "UNIX Timestamp",
        "New Earth Time",
        "Eternal September"
    ]

    @State var selectedSpecialZone: String = ""

    private var isShowingSearchResults: Bool {
        !locVM.searchResults.isEmpty && !locVM.searchText.isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Search", systemImage: "magnifyingglass")
                    .font(.headline.weight(.semibold))

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search cities or places", text: $locVM.searchText)
                        .textFieldStyle(.plain)

                    if !locVM.searchText.isEmpty {
                        Button {
                            locVM.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                )
            }
            .secondClockGlassCard(cornerRadius: 24, padding: 16, tint: Color.white.opacity(0.2))

            if isShowingSearchResults {
                SearchResultsPanel(results: locVM.searchResults)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !isShowingSearchResults {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Add")
                            .font(.headline.weight(.semibold))
                        Text("Drop in UTC or one of the playful alternate clocks.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    HStack(spacing: 10) {
                        Picker("Special", selection: $selectedSpecialZone) {
                            ForEach(specialTimeZones, id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            withAnimation {
                                let newTZ = UserTimeZone(with: selectedSpecialZone)
                                newTZ.name = selectedSpecialZone
                                modelContext.insertUserTimeZoneAtEnd(newTZ)
                            }
                        } label: {
                            Text("Add")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedSpecialZone.isEmpty)
                    }
                }
                .secondClockGlassCard(cornerRadius: 24, padding: 16, tint: Color.white.opacity(0.16))
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Saved Clocks")
                        .font(.headline.weight(.semibold))
                    Spacer()
                }

                UserTimeZoneListView()
                    .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingSearchResults)
    }
}

private struct SearchResultsPanel: View {
    let results: [MKLocalSearchCompletion]

    private var panelHeight: CGFloat {
        min(max(CGFloat(results.count) * 88, 180), 420)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(results.count) matches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(results, id: \.self) { result in
                        SearchViewRow(searchResult: result)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, minHeight: panelHeight, maxHeight: panelHeight, alignment: .top)
        }
        .secondClockGlassCard(cornerRadius: 24, padding: 16, tint: Color.white.opacity(0.22))
    }
}

struct SearchViewRow: View {
    @Environment(\.modelContext) private var modelContext

    var searchResult: MKLocalSearchCompletion

    @State var timeZone: TimeZone?
    @State private var isHidden = false
    @State var added: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(searchResult.title)
                        .font(.headline)

                    if !searchResult.subtitle.isEmpty {
                        Text(searchResult.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        let willShow = !isHidden
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHidden = willShow
                        }

                        if willShow, timeZone == nil {
                            Task { @MainActor in
                                timeZone = await LocationManager.getLocation(searchResult: searchResult)?.timeZone
                            }
                        }
                    } label: {
                        Image(systemName: isHidden ? "clock.badge.checkmark" : "clock.badge.questionmark")
                    }
                    .help("Show details")

                    Button {
                        Task { @MainActor in
                            if let location = await LocationManager.getLocation(searchResult: searchResult) {
                                guard let tz = location.timeZone else {
                                    return
                                }

                                withAnimation {
                                    let newTZ = UserTimeZone(with: tz)
                                    newTZ.name = searchResult.title
                                    newTZ.lat = location.latitude
                                    newTZ.lon = location.longitude
                                    modelContext.insertUserTimeZoneAtEnd(newTZ)
                                    added = true
                                }
                            }
                        }
                    } label: {
                        Image(systemName: added ? "star.fill" : "star")
                    }
                    .help("Add to favorites")
                }
                .buttonStyle(.borderless)
            }

            if isHidden {
                Divider()

                HStack(alignment: .firstTextBaseline) {
                    Text(timeZone?.identifier ?? "Finding time zone...")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let tz = timeZone {
                        Text(Date().convertToTimeZone(initTimeZone: TimeZone.current, timeZone: tz).formatted())
                            .font(.system(.body, design: .rounded).monospacedDigit())
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .secondClockGlassCard(cornerRadius: 20, padding: 14, tint: Color.white.opacity(0.16))
    }
}

#Preview {
    SearchView()
}
