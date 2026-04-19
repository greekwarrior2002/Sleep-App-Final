import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let claudeAPIKeyKey = "com.slumber.app.claude-api-key"

    var claudeAPIKey: String? {
        get { read(key: claudeAPIKeyKey) }
        set {
            if let value = newValue, !value.isEmpty {
                save(key: claudeAPIKeyKey, value: value)
            } else {
                delete(key: claudeAPIKeyKey)
            }
        }
    }

    var hasAPIKey: Bool { !(claudeAPIKey ?? "").isEmpty }

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
