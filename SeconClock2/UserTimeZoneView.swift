//
//  UserTimeZoneView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 17.08.23.
//

import SwiftUI

struct UserTimeZoneView: View {
    @State var tz: UserTimeZone

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var timetext = ""
    @State private var isResolvingSolarData = false

    var body: some View {
        let now = Date()
        let sunrise = tz.sunrise
        let sunset = tz.sunset
        let timeZone = tz.timezone

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                Text(timetext)
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                    .onReceive(timer) { _ in
                        timetext = time2text()
                    }
                    Text(formattedRegionDate(now))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

            }
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Set custom name", text: $tz.name.toUnwrapped(defaultValue: ""))
                        .textFieldStyle(.plain)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.12))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        }
                        .help("Set custom name")

                    HStack(spacing: 6) {

                        Label(timeZoneLabel, systemImage: "globe.europe.africa.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(offsetText)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }

                Spacer(minLength: 10)

                HStack(spacing: 6) {
                    Button {
                        tz.selected = !(tz.selected ?? false)
                    } label: {
                        Image(systemName: tz.selected == true ? "x.circle" : "menubar.rectangle")
                    }
                    .buttonStyle(ClockActionButtonStyle(isActive: tz.selected == true))
                    .help("Add to menu bar")

                    Button(role: .destructive) {
                        withAnimation {
                            tz.delete()
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(ClockActionButtonStyle(isActive: false))
                    .help("Remove from favorites")
                }
                .font(.system(size: 13, weight: .semibold))
            }



            if let timeZone, shouldShowSolarBar {
                DayTimeSliderView(
                    now: now,
                    sunset: sunset,
                    sunrise: sunrise,
                    timeZone: timeZone,
                    showsLoadingState: isResolvingSolarData || sunrise == nil || sunset == nil
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 9)

            }
        }
        .secondClockGlassCard(cornerRadius: 22, padding: 12, tint: Color.white.opacity(0.14))
        .task(id: solarLookupKey) {
            await resolveSolarLocationIfNeeded()
        }
    }

    init(tz: UserTimeZone, timetext: String = "") {
        self.tz = tz
        self.timetext = timetext
        self.timetext = time2text()
    }

    func time2text() -> String {
        tz.currentTime
    }

    private var displayName: String {
        let trimmedName = (tz.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? tz.readName() : trimmedName
    }

    private var shouldShowSolarBar: Bool {
        tz.timezone != nil && (supportsSolarLookup || hasCoordinates || isResolvingSolarData)
    }

    private var timeZoneLabel: String {
        tz.timezone?.identifier ?? tz.identifier ?? displayName
    }

    private var hasCoordinates: Bool {
        tz.lat != nil && tz.lon != nil
    }

    private var supportsSolarLookup: Bool {
        guard let identifier = tz.identifier,
              identifier.contains("/"),
              !identifier.hasPrefix("Etc/") else {
            return false
        }

        return true
    }

    private var solarLookupKey: String {
        [
            tz.identifier ?? "",
            tz.name ?? "",
            tz.lat.map { String($0) } ?? "nil",
            tz.lon.map { String($0) } ?? "nil"
        ]
        .joined(separator: "|")
    }

    private var solarLookupQueries: [String] {
        var queries: [String] = []

        if let identifier = tz.identifier, identifier.contains("/") {
            let cleanedIdentifier = identifier.replacingOccurrences(of: "_", with: " ")
            let parts = identifier.split(separator: "/").map { String($0).replacingOccurrences(of: "_", with: " ") }

            if let city = parts.last {
                queries.append(city)
            }

            queries.append(cleanedIdentifier)

            if parts.count >= 2 {
                queries.append(parts.suffix(2).joined(separator: ", "))
            }
        }

        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDisplayName.isEmpty {
            queries.append(trimmedDisplayName)
        }

        var uniqueQueries: [String] = []
        for query in queries where !uniqueQueries.contains(query) {
            uniqueQueries.append(query)
        }

        return uniqueQueries
    }

    private var offsetText: String {
        guard let timeZone = tz.timezone else {
            return "Saved"
        }

        let seconds = timeZone.secondsFromGMT(for: Date())
        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }

        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    private func formattedRegionDate(_ date: Date) -> String {
        guard let timeZone = tz.timezone else {
            return "Saved clock"
        }

        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func statusText(now: Date, sunrise: Date?, sunset: Date?) -> String {
        if isResolvingSolarData {
            return "Finding local sunrise and sunset"
        }

        guard let sunrise, let sunset else {
            return shouldShowSolarBar ? "Solar data will appear here" : "Pinned for quick access"
        }

        if now < sunrise {
            return "Night in \(displayName)"
        }

        if now > sunset {
            return "Night in \(displayName)"
        }

        return "Daytime in \(displayName)"
    }

    @MainActor
    private func resolveSolarLocationIfNeeded() async {
        guard !hasCoordinates,
              supportsSolarLookup,
              !solarLookupQueries.isEmpty,
              !isResolvingSolarData else {
            return
        }

        isResolvingSolarData = true
        defer {
            isResolvingSolarData = false
        }

        guard let location = await LocationManager.getLocation(queries: solarLookupQueries) else {
            return
        }

        tz.lat = location.latitude
        tz.lon = location.longitude
    }
}

#Preview {
    UserTimeZoneView(tz: UserTimeZone(with: "Africa/Kigali"))
        .padding()
}

extension Binding {
    func toUnwrapped<T: Sendable>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}

private struct ClockActionButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isActive ? Color.accentColor : Color.white.opacity(0.92))
            .frame(width: 30, height: 30)
            .background(
                Circle()
                    .fill(isActive ? Color.accentColor.opacity(0.18) : Color.black.opacity(0.16))
            )
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
