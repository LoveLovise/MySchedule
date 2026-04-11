//
//  MyScheduleApp.swift
//  MySchedule
//
//  Created by Aaron on 8/1/25.
//

import SwiftUI
import SwiftData

@main
struct MyScheduleApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject private var scheduleManager = ScheduleManager()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self, ScheduleItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()                
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
    }
}
