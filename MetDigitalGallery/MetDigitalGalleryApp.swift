//
//  MetDigitalGalleryApp.swift
//  MetDigitalGallery
//
//  @main entry point.
//
//  Inspo Board feature (Apr 2026):
//  Installs a SwiftData ModelContainer for SavedBoard + BoardCollection so
//  user-saved inspo boards persist across launches. The container is
//  shared across the whole view hierarchy via .modelContainer(...).
//

import SwiftUI
import SwiftData

@main
struct MetDigitalGalleryApp: App {

    /// Shared SwiftData container. Schema lists every @Model type used
    /// in the app. If you add new persistent models, add them here too.
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedBoard.self,
            BoardCollection.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If the store fails to open we can't realistically recover,
            // so trap loudly — running without persistence would silently
            // lose the user's saved boards.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
