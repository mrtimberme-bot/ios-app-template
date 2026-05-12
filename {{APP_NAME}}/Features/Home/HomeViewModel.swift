import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var isLoading = false

    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        // Implementeer data laden
    }
}
