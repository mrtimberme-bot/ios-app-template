import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case serverError(statusCode: Int)
    case decodingFailed
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            "Geen internetverbinding. Controleer je verbinding en probeer opnieuw."
        case .serverError(let code):
            "Er is een serverfout opgetreden (code \(code)). Probeer het later opnieuw."
        case .decodingFailed:
            "De gegevens konden niet worden verwerkt."
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
