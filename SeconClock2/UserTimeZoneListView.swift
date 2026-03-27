//
//  UserTimeZoneListView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 17.08.23.
//

import SwiftUI
import SwiftData

struct UserTimeZoneListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\UserTimeZone.order)]) private var timeZones: [UserTimeZone]

    private var sortedTimeZones: [UserTimeZone] {
        Array(timeZones.enumerated())
            .sorted { lhs, rhs in
                let leftOrder = lhs.element.order ?? Int.max
                let rightOrder = rhs.element.order ?? Int.max

                if leftOrder != rightOrder {
                    return leftOrder < rightOrder
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private var orderSignature: String {
        sortedTimeZones
            .map { "\($0.identifier ?? $0.readName()):\($0.order.map(String.init) ?? "nil")" }
            .joined(separator: "|")
    }

    var body: some View {
        Group {
            if sortedTimeZones.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "globe.europe.africa.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)

                    Text("No clocks saved yet")
                        .font(.headline)

                    Text("Search for a place above, then add it to keep it in your menu bar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 240)
                }
                .frame(maxWidth: .infinity, minHeight: 240)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedTimeZones) { zone in
                        UserTimeZoneView(tz: zone)
                    }
                }
                .padding(.vertical, 2)
                .background(Color.clear)
            }
        }
        .task(id: orderSignature) {
            modelContext.normalizeUserTimeZoneOrders(using: sortedTimeZones)
        }
    }
}

#Preview {
    UserTimeZoneListView()
}
