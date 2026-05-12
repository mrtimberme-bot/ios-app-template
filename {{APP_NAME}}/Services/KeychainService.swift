import Foundation
import Security
import OSLog

private let logger = Logger(subsystem: "{{BUNDLE_ID}}", category: "Keychain")

protocol KeychainServicing: Sendable {
    func value(for key: String) -> String?
    func set(_ value: String, for key: String) throws
    func delete(for key: String)
}

final class KeychainService: KeychainServicing {
    static let shared = KeychainService()
    private init() {}

    func value(for key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        delete(for: key)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Keychain set mislukt voor \(key): \(status)")
            throw KeychainError.saveFailed(status: status)
        }
    }

    func delete(for key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): "Keychain opslaan mislukt (status \(status))"
        }
    }
}
