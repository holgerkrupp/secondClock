//
//  AppIntent.swift
//  Second Clock Widget
//
//  Created by Holger Krupp on 25.08.23.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    // An example configurable parameter.
    @Parameter(title: "Favorite Emojissss", default: "😃")
    var favoriteEmoji: String
}
