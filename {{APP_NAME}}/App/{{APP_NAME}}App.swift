import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "{{BUNDLE_ID}}", category: "App")

@main
struct {{APP_NAME}}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: sharedModelContainer)
        }
    }
}

private var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        // Voeg @Model types toe hier
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        logger.critical("ModelContainer aanmaken mislukt: \(error)")
        fatalError("ModelContainer aanmaken mislukt: \(error)")
    }
}()
