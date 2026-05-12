import Network
import Observation
import OSLog

private let logger = Logger(subsystem: "{{BUNDLE_ID}}", category: "Network")

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected = true
    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
            logger.info("Netwerkstatus: \(connected ? "verbonden" : "verbroken")")
        }
        monitor.start(queue: DispatchQueue(label: "{{BUNDLE_ID}}.networkmonitor"))
    }
}
