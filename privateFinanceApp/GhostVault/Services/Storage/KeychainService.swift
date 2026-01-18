//
//  KeychainService.swift
//  GhostVault
//
//  Secure storage for SimpleFIN access token using iOS Keychain
//

import Foundation
import Security

class KeychainService {
    private let serviceName = "com.ghostvault.app"
    private let accessURLKey = "simplefin_access_url"

    // MARK: - Access URL Storage

    func saveAccessURL(_ accessURL: String) {
        guard let data = accessURL.data(using: .utf8) else { return }

        // Delete any existing item first
        deleteAccessURL()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accessURLKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func getAccessURL() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accessURLKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let accessURL = String(data: data, encoding: .utf8) else {
            return nil
        }

        return accessURL
    }

    func hasAccessURL() -> Bool {
        return getAccessURL() != nil
    }

    func deleteAccessURL() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accessURLKey
        ]

        SecItemDelete(query as CFDictionary)
    }
}
