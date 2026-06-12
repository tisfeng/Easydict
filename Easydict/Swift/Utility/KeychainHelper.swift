//
//  KeychainHelper.swift
//  Easydict
//
//  Security fix: Store API keys in macOS Keychain instead of UserDefaults.
//

import Foundation
import Security

enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "com.izual.Easydict"

    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func readOrEmpty(_ key: String) -> String {
        read(key) ?? ""
    }
}

// MARK: - Migration from UserDefaults

@objc(SecureStorageMigration)
@objcMembers
final class SecureStorageMigration: NSObject {
    private static let migrationDoneKey = "EZ_KeychainMigrationDone_v1"

    static let sensitiveKeys: [String] = [
        "EZDeepLAuthKey",
        "EZBingCookieKey",
        "EZNiuTransAPIKey",
        "EZCaiyunToken",
        "EZTencentSecretId",
        "EZTencentSecretKey",
        "EZAliAccessKeyId",
        "EZAliAccessKeySecret",
        "EZBaiduAppId",
        "EZBaiduSecretKey",
        "EZVolcanoAccessKeyID",
        "EZVolcanoSecretAccessKey",
        "EZDoubaoAPIKey",
    ]

    static func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationDoneKey) else { return }

        for key in sensitiveKeys {
            if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
                if KeychainHelper.read(key) == nil {
                    KeychainHelper.save(value, forKey: key)
                }
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        migrateStreamServiceKeys()

        UserDefaults.standard.set(true, forKey: migrationDoneKey)
        UserDefaults.standard.synchronize()
    }

    private static func migrateStreamServiceKeys() {
        let defaults = UserDefaults.standard
        guard let bundleId = Bundle.main.bundleIdentifier,
              let domain = defaults.persistentDomain(forName: bundleId) else { return }

        for (key, value) in domain {
            guard let stringValue = value as? String, !stringValue.isEmpty else { continue }
            let isAPIKey = key.hasSuffix("-apiKey") || key.hasSuffix("APIKey")
            if isAPIKey {
                if KeychainHelper.read(key) == nil {
                    KeychainHelper.save(stringValue, forKey: key)
                }
                defaults.removeObject(forKey: key)
            }
        }
    }

    /// Sync any new values written to UserDefaults back to Keychain (called after settings close).
    static func syncSensitiveKeys() {
        for key in sensitiveKeys {
            if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
                KeychainHelper.save(value, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        syncStreamServiceKeys()
    }

    private static func syncStreamServiceKeys() {
        let defaults = UserDefaults.standard
        guard let bundleId = Bundle.main.bundleIdentifier,
              let domain = defaults.persistentDomain(forName: bundleId) else { return }

        for (key, value) in domain {
            guard let stringValue = value as? String, !stringValue.isEmpty else { continue }
            if key.hasSuffix("-apiKey") || key.hasSuffix("APIKey") {
                KeychainHelper.save(stringValue, forKey: key)
                defaults.removeObject(forKey: key)
            }
        }
    }
}
