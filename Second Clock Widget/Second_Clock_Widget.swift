//
//  Second_Clock_Widget.swift
//  Second Clock Widget
//
//  Created by Holger Krupp on 25.08.23.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let LA = TimeZone(identifier: "America/Los_Angeles")
        let cupertino = UserTimeZone(with: LA!)
        cupertino.lat = 37.332914
        cupertino.lon = -122.005202
        cupertino.name = "Cupertino"
        cupertino.identifier = cupertino.timezone?.identifier
            
            
        
        
        return SimpleEntry(date: Date(), timezone: cupertino, configuration: ConfigurationAppIntent())

    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let LA = TimeZone(identifier: "America/Los_Angeles")
        let cupertino = UserTimeZone(with: LA!)
        cupertino.lat = 37.332914
        cupertino.lon = -122.005202
        cupertino.name = "Cupertino"
        cupertino.identifier = cupertino.timezone?.identifier
        
        
        
        
        return SimpleEntry(date: Date(), timezone: cupertino, configuration: ConfigurationAppIntent())    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, timezone: UserTimeZone(with: TimeZone(identifier: "America/Los_Angeles")!), configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timezone: UserTimeZone
    let configuration: ConfigurationAppIntent
}

struct Second_Clock_WidgetEntryView : View {
    var entry: Provider.Entry
  
    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            
            Text(entry.timezone.readName())
            Text(entry.timezone.currentTime)
        }
    }
}

struct Second_Clock_Widget: Widget {
    let kind: String = "Second_Clock_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Second_Clock_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
