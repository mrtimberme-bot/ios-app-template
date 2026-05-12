import OSLog

extension Logger {
    private static let subsystem = "{{BUNDLE_ID}}"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
