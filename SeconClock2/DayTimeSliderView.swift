//
//  DayTimeSliderView.swift
//  SecondClock2
//
//  Created by Holger Krupp on 22.08.23.
//

import SwiftUI

struct DayTimeSliderView: View {
    private enum SolarEventKind {
        case sunrise
        case sunset

        var title: String {
            switch self {
            case .sunrise:
                return "Sunrise"
            case .sunset:
                return "Sunset"
            }
        }

        var symbol: String {
            switch self {
            case .sunrise:
                return "sunrise.fill"
            case .sunset:
                return "sunset.fill"
            }
        }

        var color: Color {
            switch self {
            case .sunrise:
                return .yellow
            case .sunset:
                return .orange
            }
        }
    }

    private struct SolarEventPlacement: Identifiable {
        let kind: SolarEventKind
        let date: Date
        let position: CGFloat

        var id: String {
            "\(kind.title)-\(date.timeIntervalSince1970)"
        }
    }

    var now: Date?
    var sunset: Date?
    var sunrise: Date?
    var timeZone: TimeZone?
    var showsLoadingState: Bool = false

    private let secondsInADay: TimeInterval = 24 * 60 * 60
    private let halfDay: TimeInterval = 12 * 60 * 60
    private let relativeDayOffsets: [TimeInterval] = [-24 * 60 * 60, 0, 24 * 60 * 60]
    private let trackHeight: CGFloat = 0
    // Night clock face from the app icon: deep navy blue.
    private let nightTrackGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.08, blue: 0.20),
            Color(red: 0.11, green: 0.16, blue: 0.33)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    // Day clock face from the app icon: light sky blue.
    private let daylightGradient = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.81, blue: 0.98),
            Color(red: 0.35, green: 0.64, blue: 0.92)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private var hasSolarEvents: Bool {
        sunrise != nil && sunset != nil
    }

    private var referenceDate: Date {
        now ?? Date()
    }

    private var normalizedSolarInterval: (sunrise: Date, sunset: Date)? {
        guard let sunrise, let sunset else {
            return nil
        }

        if sunset > sunrise {
            return (sunrise, sunset)
        }

        return (sunrise, sunset.addingTimeInterval(secondsInADay))
    }

    private var visibleDaylightRanges: [ClosedRange<CGFloat>] {
        guard let solarInterval = normalizedSolarInterval else {
            return []
        }

        return relativeDayOffsets.compactMap { dayOffset in
            let shiftedSunrise = solarInterval.sunrise.addingTimeInterval(dayOffset)
            let shiftedSunset = solarInterval.sunset.addingTimeInterval(dayOffset)

            let startOffset = shiftedSunrise.timeIntervalSince(referenceDate)
            let endOffset = shiftedSunset.timeIntervalSince(referenceDate)

            let clippedStart = max(startOffset, -halfDay)
            let clippedEnd = min(endOffset, halfDay)

            guard clippedStart < clippedEnd else {
                return nil
            }

            let lowerBound = CGFloat(0.5 + (clippedStart / secondsInADay))
            let upperBound = CGFloat(0.5 + (clippedEnd / secondsInADay))
            return lowerBound...upperBound
        }
    }

    private var visibleSolarEvents: [SolarEventPlacement] {
        guard let solarInterval = normalizedSolarInterval else {
            return []
        }

        return visiblePlacements(kind: .sunrise, baseDate: solarInterval.sunrise)
            + visiblePlacements(kind: .sunset, baseDate: solarInterval.sunset)
    }

    private var sunrisePlacement: SolarEventPlacement? {
        visibleSolarEvents.first { $0.kind == .sunrise }
    }

    private var sunsetPlacement: SolarEventPlacement? {
        visibleSolarEvents.first { $0.kind == .sunset }
    }

    private func visiblePlacements(kind: SolarEventKind, baseDate: Date?) -> [SolarEventPlacement] {
        guard let baseDate else {
            return []
        }

        return relativeDayOffsets.compactMap { dayOffset in
            let shiftedDate = baseDate.addingTimeInterval(dayOffset)
            let offset = shiftedDate.timeIntervalSince(referenceDate)

            guard offset >= -halfDay, offset <= halfDay else {
                return nil
            }

            return SolarEventPlacement(
                kind: kind,
                date: shiftedDate,
                position: CGFloat(0.5 + (offset / secondsInADay))
            )
        }
        .sorted { $0.position < $1.position }
    }

    private var isCurrentlyDaylight: Bool {
        guard now != nil, let solarInterval = normalizedSolarInterval else {
            return false
        }

        return relativeDayOffsets.contains { dayOffset in
            let shiftedSunrise = solarInterval.sunrise.addingTimeInterval(dayOffset)
            let shiftedSunset = solarInterval.sunset.addingTimeInterval(dayOffset)
            return referenceDate >= shiftedSunrise && referenceDate <= shiftedSunset
        }
    }

    private var daylightDurationText: String? {
        guard let solarInterval = normalizedSolarInterval else {
            return nil
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2

        guard let duration = formatter.string(from: solarInterval.sunset.timeIntervalSince(solarInterval.sunrise)) else {
            return nil
        }

        return "\(duration) of daylight"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if hasSolarEvents {
                    Label(
                        isCurrentlyDaylight ? "Daylight now" : "Night now",
                        systemImage: isCurrentlyDaylight ? "sun.max.fill" : "moon.stars.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrentlyDaylight ? Color.orange : Color.white.opacity(0.92))
                } else {
                    Label(
                        showsLoadingState ? "Finding sunrise and sunset" : "Daylight estimate",
                        systemImage: showsLoadingState ? "location.magnifyingglass" : "sun.max"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let daylightDurationText {
                    Text(daylightDurationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if showsLoadingState {
                    Text("Updating")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Centered on your current time")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geometry in
                let width = max(geometry.size.width, 1)
                let centerX = width * 0.5

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(nightTrackGradient)
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.04),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .overlay {
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        }

                    ForEach(Array(visibleDaylightRanges.enumerated()), id: \.offset) { _, range in
                        let segmentWidth = max(width * (range.upperBound - range.lowerBound), 2)

                        Rectangle()
                            .fill(daylightGradient)
                            .overlay {
                                Rectangle()
                                    .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.8)
                            }
                            .frame(width: segmentWidth)
                            .offset(x: width * range.lowerBound)
                            .shadow(color: Color(red: 0.45, green: 0.72, blue: 0.96).opacity(0.30), radius: 10, y: 0)
                    }

                    ForEach(visibleSolarEvents) { placement in
                        phaseTick(
                            symbol: placement.kind.symbol,
                            color: placement.kind.color,
                            position: width * placement.position
                        )
                    }

                    if now != nil {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 3, height: trackHeight+10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .stroke(Color.black.opacity(0.22), lineWidth: 0.8)
                            }
                            .overlay(alignment: .top) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 9, height: 9)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                    )
                                    .offset(y: -6)
                            }
                            .offset(x: centerX - 1.5, y: -5)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 0)
                    }
                }
            }
            .frame(height: trackHeight + 15)

            if hasSolarEvents {
               
                HStack(spacing: 12) {
                    if let sunrisePlacement {
                        phaseLabel(
                            title: sunrisePlacement.kind.title,
                            time: sunrisePlacement.date,
                            symbol: sunrisePlacement.kind.symbol,
                            color: sunrisePlacement.kind.color
                        )
                    } else {
                        phaseLabel(
                            title: SolarEventKind.sunrise.title,
                            time: normalizedSolarInterval?.sunrise,
                            symbol: SolarEventKind.sunrise.symbol,
                            color: SolarEventKind.sunrise.color
                        )
                    }

                    Spacer(minLength: 12)

                    if let sunsetPlacement {
                        phaseLabel(
                            title: sunsetPlacement.kind.title,
                            time: sunsetPlacement.date,
                            symbol: sunsetPlacement.kind.symbol,
                            color: sunsetPlacement.kind.color
                        )
                    } else {
                        phaseLabel(
                            title: SolarEventKind.sunset.title,
                            time: normalizedSolarInterval?.sunset,
                            symbol: SolarEventKind.sunset.symbol,
                            color: SolarEventKind.sunset.color
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func phaseTick(symbol: String, color: Color, position: CGFloat) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.35), radius: 4, y: 0)

            Capsule(style: .continuous)
                .fill(color.opacity(0.9))
                .frame(width: 2, height: trackHeight + 4)
        }
        .offset(x: position - 7, y: -2)
    }

    @ViewBuilder
    private func phaseLabel(title: String, time: Date?, symbol: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)



                Text(formattedTime(time))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            
        }
    }

    private func formattedTime(_ date: Date?) -> String {
        guard let date else {
            return "--"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = timeZone ?? .current
        return formatter.string(from: date)
    }
}

#Preview {
    DayTimeSliderView(
        now: Date(),
        sunset: Calendar.current.date(byAdding: .hour, value: 6, to: Date()),
        sunrise: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
    )
}

extension Date {
    var percetageOfDay: Float {
        Float(percentageOfDay(in: .current))
    }

    func percentageOfDay(in timeZone: TimeZone?) -> Double {
        let secondsInADay = 24 * 60 * 60

        var calendar = Calendar.current
        calendar.timeZone = timeZone ?? .current

        let hourSeconds = calendar.component(.hour, from: self) * 60 * 60
        let minuteSeconds = calendar.component(.minute, from: self) * 60
        let seconds = calendar.component(.second, from: self)

        let totalSeconds = hourSeconds + minuteSeconds + seconds
        let passedSeconds = Double(totalSeconds) / Double(secondsInADay)

        return passedSeconds
    }
}
