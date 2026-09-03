//
//  EZSchemeParserTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import CoreFoundation
import Foundation
import Testing

@testable import Easydict

// MARK: - EZSchemeParserTests

/// Verifies that URL Scheme automation remains useful while failing closed around secrets.
@Suite("Easydict URL Scheme", .serialized, .tags(.unit))
struct EZSchemeParserTests {
    // MARK: Internal

    @Test("Rejects static and dynamic credentials without changing defaults or pasteboard")
    func rejectsCredentialReadAndWrite() {
        let uuid = "00000000-0000-4000-8000-000000000010"
        let dynamicKey = "EZ\(ServiceType.customOpenAI.rawValue)API_\(uuid)_Key"
        let credentialKeys = ["EZDeepLAuthKey", dynamicKey]
        let defaultsSnapshot = snapshotDefaults(keys: credentialKeys)
        let pasteboardSnapshot = snapshotPasteboard()
        defer {
            restoreDefaults(defaultsSnapshot)
            restorePasteboard(pasteboardSnapshot)
        }

        let pasteboardCanary = "scheme-test-pasteboard-canary"
        NSPasteboard.general.clearContents()
        #expect(NSPasteboard.general.setString(pasteboardCanary, forType: .string))

        for (index, key) in credentialKeys.enumerated() {
            let storedCanary = "stored-credential-canary-\(index)"
            UserDefaults.standard.set(storedCanary, forKey: key)

            let writeResult = open(
                action: "writeKeyValue",
                queryItems: [.init(name: key, value: "replacement-credential-canary")]
            )
            #expect(!writeResult.isSuccess)
            #expect(writeResult.returnValue == "Write Failed")
            #expect(writeResult.actionKey == "writeKeyValue")
            #expect(UserDefaults.standard.string(forKey: key) == storedCanary)
            #expect(NSPasteboard.general.string(forType: .string) == pasteboardCanary)

            let readResult = open(
                action: "readValueOfKey",
                queryItems: [.init(name: key, value: nil)]
            )
            #expect(!readResult.isSuccess)
            #expect(readResult.returnValue == nil)
            #expect(readResult.actionKey == "readValueOfKey")
            #expect(UserDefaults.standard.string(forKey: key) == storedCanary)
            #expect(NSPasteboard.general.string(forType: .string) == pasteboardCanary)
        }
    }

    @Test("Rejects an unsafe endpoint atomically")
    func rejectsUnsafeEndpointWrite() {
        let endpointKey = "EZDeepLTranslateEndPointKey"
        let settingKey = "IntelligentQueryMode-window1"
        let defaultsSnapshot = snapshotDefaults(keys: [endpointKey, settingKey])
        defer { restoreDefaults(defaultsSnapshot) }

        UserDefaults.standard.set("https://api.example.test", forKey: endpointKey)
        UserDefaults.standard.set("existing-query-mode", forKey: settingKey)

        let result = open(
            action: "writeKeyValue",
            queryItems: [
                .init(name: settingKey, value: "replacement-query-mode"),
                .init(name: endpointKey, value: "http://api.example.test"),
            ]
        )

        #expect(!result.isSuccess)
        #expect(result.returnValue == "Write Failed")
        #expect(result.actionKey == "writeKeyValue")
        #expect(UserDefaults.standard.string(forKey: endpointKey) == "https://api.example.test")
        #expect(UserDefaults.standard.string(forKey: settingKey) == "existing-query-mode")
    }

    @Test("Rejects endpoint writes even when the HTTPS value is valid")
    func rejectsValidHTTPSEndpointWrite() {
        let endpointKey = "EZDeepLTranslateEndPointKey"
        let existingEndpoint = "https://existing.api.example.test/v1"
        let defaultsSnapshot = snapshotDefaults(keys: [endpointKey])
        defer { restoreDefaults(defaultsSnapshot) }
        UserDefaults.standard.set(existingEndpoint, forKey: endpointKey)

        let result = open(
            action: "writeKeyValue",
            queryItems: [
                .init(name: endpointKey, value: "https://replacement.api.example.test/v2"),
            ]
        )

        #expect(!result.isSuccess)
        #expect(result.returnValue == "Write Failed")
        #expect(result.actionKey == "writeKeyValue")
        #expect(UserDefaults.standard.string(forKey: endpointKey) == existingEndpoint)
    }

    @Test(
        "Rejects userinfo in endpoint writes",
        arguments: [
            "https://user@api.example.test/v1",
            "https://user" + ":password@api.example.test/v1",
            "https://us%65r" + ":p%40ssword@api.example.test/v1",
        ]
    )
    func rejectsUserInfoEndpointWrite(_ endpoint: String) {
        let endpointKey = "EZDeepLTranslateEndPointKey"
        let defaultsSnapshot = snapshotDefaults(keys: [endpointKey])
        defer { restoreDefaults(defaultsSnapshot) }
        UserDefaults.standard.set("https://api.example.test/v1", forKey: endpointKey)

        let result = open(
            action: "writeKeyValue",
            queryItems: [.init(name: endpointKey, value: endpoint)]
        )

        #expect(!result.isSuccess)
        #expect(result.returnValue == "Write Failed")
        #expect(result.actionKey == "writeKeyValue")
        #expect(UserDefaults.standard.string(forKey: endpointKey) == "https://api.example.test/v1")
    }

    @Test("Keeps endpoint automation write-only even for a valid saved HTTPS value")
    func rejectsEndpointReadWithoutChangingPasteboard() {
        let endpointKey = "EZDeepLTranslateEndPointKey"
        let endpoint = "https://api.example.test/v1/tenant?token=endpoint-canary"
        let pasteboardCanary = "scheme-endpoint-read-pasteboard-canary"
        let defaultsSnapshot = snapshotDefaults(keys: [endpointKey])
        let pasteboardSnapshot = snapshotPasteboard()
        defer {
            restoreDefaults(defaultsSnapshot)
            restorePasteboard(pasteboardSnapshot)
        }
        UserDefaults.standard.set(endpoint, forKey: endpointKey)
        NSPasteboard.general.clearContents()
        #expect(NSPasteboard.general.setString(pasteboardCanary, forType: .string))

        let result = open(
            action: "readValueOfKey",
            queryItems: [.init(name: endpointKey, value: nil)]
        )

        #expect(!result.isSuccess)
        #expect(result.returnValue == nil)
        #expect(result.actionKey == "readValueOfKey")
        #expect(UserDefaults.standard.string(forKey: endpointKey) == endpoint)
        #expect(NSPasteboard.general.string(forType: .string) == pasteboardCanary)
    }

    @Test("Keeps registered non-sensitive setting and query automation available")
    func allowsKnownNonSensitiveAutomation() {
        let automatedValues = [
            "EZDeepLTranslationAPIKey": "1",
            "IntelligentQueryMode-window2": "test-query-mode",
        ]
        let defaultsSnapshot = snapshotDefaults(keys: Array(automatedValues.keys))
        let pasteboardSnapshot = snapshotPasteboard()
        defer {
            restoreDefaults(defaultsSnapshot)
            restorePasteboard(pasteboardSnapshot)
        }

        for (key, value) in automatedValues {
            let writeResult = open(
                action: "writeKeyValue",
                queryItems: [.init(name: key, value: value)]
            )
            #expect(writeResult.isSuccess)
            #expect(writeResult.returnValue == "Write Success")
            #expect(writeResult.actionKey == "writeKeyValue")
            #expect(UserDefaults.standard.string(forKey: key) == value)

            NSPasteboard.general.clearContents()
            let readResult = open(
                action: "readValueOfKey",
                queryItems: [.init(name: key, value: nil)]
            )
            #expect(readResult.isSuccess)
            #expect(readResult.returnValue == value)
            #expect(readResult.actionKey == "readValueOfKey")
            #expect(NSPasteboard.general.string(forType: .string) == value)
        }
    }

    @Test("Stores an automated boolean setting as a property-list boolean")
    func parsesBooleanSettingValue() throws {
        let uuid = "00000000-0000-4000-8000-000000000012"
        let key = "EZ\(ServiceType.customOpenAI.rawValue)EnableStreaming_\(uuid)_Key"
        let defaultsSnapshot = snapshotDefaults(keys: [key])
        defer { restoreDefaults(defaultsSnapshot) }

        let result = open(
            action: "writeKeyValue",
            queryItems: [.init(name: key, value: "1")]
        )

        #expect(result.isSuccess)
        let storedValue = try #require(UserDefaults.standard.object(forKey: key) as? NSNumber)
        #expect(CFGetTypeID(storedValue) == CFBooleanGetTypeID())
        #expect(storedValue.boolValue)
        #expect(!(UserDefaults.standard.object(forKey: key) is String))
    }

    @Test("Rejects URL payloads on reset and export without changing coordinator state")
    func rejectsParametersForConfirmationActions() async {
        let coordinator = ConfigurationSchemeActionCoordinator.shared
        clearPendingAction(coordinator)
        defer { clearPendingAction(coordinator) }

        for action in ["resetUserDefaultsData", "saveUserDefaultsDataToDownloadFolder"] {
            var queryComponents = URLComponents()
            queryComponents.scheme = "easydict"
            queryComponents.host = action
            queryComponents.queryItems = [
                URLQueryItem(name: "password", value: "must-not-be-consumed"),
                URLQueryItem(name: "path", value: "/tmp/must-not-be-written"),
                URLQueryItem(name: "data", value: "must-not-be-imported"),
            ]
            let rejectedURLs = [
                queryComponents.string ?? "",
                "easydict://\(action)/unexpected-path",
                "easydict://\(action)#unexpected-fragment",
                "easydict://automation@\(action)",
            ]

            for url in rejectedURLs {
                let result = open(url: url)
                await drainMainQueue()

                #expect(!result.isSuccess)
                #expect(coordinator.pendingAction == .none)
                clearPendingAction(coordinator)
            }
        }
    }

    @Test("Queues reset confirmation without immediately clearing defaults")
    func queuesResetConfirmation() async {
        let sentinelKey = "easydict.tests.scheme.reset-sentinel"
        let defaultsSnapshot = snapshotDefaults(keys: [sentinelKey])
        let coordinator = ConfigurationSchemeActionCoordinator.shared
        clearPendingAction(coordinator)
        defer {
            coordinator.consume(.reset)
            restoreDefaults(defaultsSnapshot)
        }
        UserDefaults.standard.set("preserved", forKey: sentinelKey)

        let result = open(action: "resetUserDefaultsData")

        #expect(result.isSuccess)
        #expect(result.returnValue == "Confirmation Required")
        #expect(result.actionKey == "resetUserDefaultsData")
        #expect(UserDefaults.standard.string(forKey: sentinelKey) == "preserved")
        await drainMainQueue()
        #expect(coordinator.pendingAction == .reset)
        #expect(UserDefaults.standard.string(forKey: sentinelKey) == "preserved")
    }

    @Test("Queues encrypted export instead of performing the legacy direct export")
    func queuesEncryptedExport() async {
        let sentinelKey = "easydict.tests.scheme.export-sentinel"
        let defaultsSnapshot = snapshotDefaults(keys: [sentinelKey])
        let coordinator = ConfigurationSchemeActionCoordinator.shared
        clearPendingAction(coordinator)
        defer {
            coordinator.consume(.encryptedExport)
            restoreDefaults(defaultsSnapshot)
        }
        UserDefaults.standard.set("preserved", forKey: sentinelKey)

        let result = open(action: "saveUserDefaultsDataToDownloadFolder")

        #expect(result.isSuccess)
        #expect(result.returnValue == "Encrypted Backup Opened")
        #expect(result.actionKey == "saveUserDefaultsDataToDownloadFolder")
        #expect(UserDefaults.standard.string(forKey: sentinelKey) == "preserved")
        await drainMainQueue()
        #expect(coordinator.pendingAction == .encryptedExport)
        #expect(UserDefaults.standard.string(forKey: sentinelKey) == "preserved")
    }

    // MARK: Private

    // MARK: - Helpers

    private struct SchemeResult {
        let isSuccess: Bool
        let returnValue: String?
        let actionKey: String?
    }

    private struct DefaultsSnapshot {
        let values: [String: Any]
        let absentKeys: Set<String>
    }

    private func open(
        action: String,
        queryItems: [URLQueryItem] = []
    )
        -> SchemeResult {
        var components = URLComponents()
        components.scheme = "easydict"
        components.host = action
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return open(url: components.string ?? "")
    }

    private func open(url: String) -> SchemeResult {
        var result: SchemeResult?
        EZSchemeParserTestBridge.openURLScheme(url) { isSuccess, returnValue, actionKey in
            result = SchemeResult(
                isSuccess: isSuccess,
                returnValue: returnValue,
                actionKey: actionKey
            )
        }
        return result ?? SchemeResult(isSuccess: false, returnValue: nil, actionKey: nil)
    }

    private func snapshotDefaults(keys: [String]) -> DefaultsSnapshot {
        var values = [String: Any]()
        var absentKeys = Set<String>()
        for key in keys {
            if let value = UserDefaults.standard.object(forKey: key) {
                values[key] = value
            } else {
                absentKeys.insert(key)
            }
        }
        return DefaultsSnapshot(values: values, absentKeys: absentKeys)
    }

    private func restoreDefaults(_ snapshot: DefaultsSnapshot) {
        for key in snapshot.absentKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        for (key, value) in snapshot.values {
            UserDefaults.standard.set(value, forKey: key)
        }
    }

    private func snapshotPasteboard() -> [NSPasteboardItem] {
        (NSPasteboard.general.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    private func restorePasteboard(_ items: [NSPasteboardItem]) {
        NSPasteboard.general.clearContents()
        if !items.isEmpty {
            NSPasteboard.general.writeObjects(items)
        }
    }

    private func clearPendingAction(_ coordinator: ConfigurationSchemeActionCoordinator) {
        coordinator.consume(.reset)
        coordinator.consume(.encryptedExport)
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }
}

// MARK: - EZSchemeParserTestBridge

/// Invokes the internal Objective-C parser without widening its production header visibility.
enum EZSchemeParserTestBridge {
    typealias Completion = (Bool, String?, String?) -> ()

    static func openURLScheme(
        _ url: String,
        completion: @escaping Completion
    ) {
        typealias ObjectiveCCompletion = @convention(block) (Bool, NSString?, NSString?) -> ()
        typealias OpenURLSchemeImplementation = @convention(c) (
            AnyObject,
            Selector,
            NSString,
            ObjectiveCCompletion
        )
            -> ()

        guard let parserClass = NSClassFromString("EZSchemeParser") as? NSObject.Type else {
            completion(false, "EZSchemeParser is unavailable", nil)
            return
        }
        let parser = parserClass.init()
        let selector = NSSelectorFromString("openURLScheme:completion:")
        guard parser.responds(to: selector) else {
            completion(false, "EZSchemeParser selector is unavailable", nil)
            return
        }

        let implementation = parser.method(for: selector)
        let openURLScheme = unsafeBitCast(
            implementation,
            to: OpenURLSchemeImplementation.self
        )
        let objectiveCCompletion: ObjectiveCCompletion = { isSuccess, returnValue, actionKey in
            completion(isSuccess, returnValue as String?, actionKey as String?)
        }
        openURLScheme(parser, selector, url as NSString, objectiveCCompletion)
    }
}
