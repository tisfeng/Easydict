//
//  ConfigurationBackupServiceTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreFoundation
import Foundation
import Testing

@testable import Easydict

// MARK: - ConfigurationBackupServiceTests

/// Verifies backup scope, restore previews, merge overlays, and transactional rollback behavior.
@Suite("Configuration Backup Service", .serialized, .tags(.unit))
struct ConfigurationBackupServiceTests {
    // MARK: Internal

    @Test("Requires a confirmed portable-backup password")
    func validatesBackupPassword() {
        let service = makeService(domain: [:])

        #expect(throws: ConfigurationBackupError.passwordTooShort) {
            try service.exportData(password: "too-short", confirmation: "too-short")
        }
        #expect(throws: ConfigurationBackupError.passwordMismatch) {
            try service.exportData(password: password, confirmation: "different-password")
        }
    }

    @Test("Exports only registered settings, service metadata, and credentials")
    func exportsOnlyAllowedConfigurationScope() throws {
        let credentialCanary = "FAKE_EXPORT_CREDENTIAL_MUST_NOT_APPEAR"
        let historyCanary = "PRIVATE_HISTORY_MUST_NOT_APPEAR"
        let service = ServiceType.customOpenAI.rawValue
        let uuid = "00000000-0000-4000-8000-000000000003"
        let serviceInfoKey = "kServiceInfoStorageKey-\(service)-\(uuid)-1"
        let serviceInfo = Data("semantic-service-metadata".utf8)
        let source = makeService(domain: [
            "EZConfiguration_kApperanceKey": NSNumber(value: 2),
            "EZDeepLAuthKey": credentialCanary,
            serviceInfoKey: serviceInfo,
            "EZConfiguration_kQueryHistory": [historyCanary],
            "EZConfiguration_kFavorites": ["private-favorite"],
            "kQueryCountKey": 99,
            "future.unregistered.key": "unsupported",
        ])

        let encrypted = try source.exportData(
            password: password,
            confirmation: password,
            now: fixedDate
        )

        #expect(encrypted.range(of: Data(credentialCanary.utf8)) == nil)
        #expect(encrypted.range(of: Data(historyCanary.utf8)) == nil)
        #expect(encrypted.range(of: Data("EZDeepLAuthKey".utf8)) == nil)
        #expect(encrypted.range(of: Data("credential.deepl.auth".utf8)) == nil)
        #expect(encrypted.range(of: Data(serviceInfoKey.utf8)) == nil)
        #expect(encrypted.range(of: Data("service.instance".utf8)) == nil)
        let payload = try ConfigurationBackupCodec.decrypt(encrypted, password: password)
        #expect(payload.createdAt == fixedDate)
        #expect(payload.items.count == 3)
        let descriptors = Set(payload.items.map(\.descriptor.name))
        #expect(descriptors == [
            "setting.appearance",
            "credential.deepl.auth",
            "service.instance",
        ])
        #expect(payload.items.allSatisfy { !$0.descriptor.name.contains("history") })
        #expect(payload.items.allSatisfy { !$0.descriptor.name.contains("favorite") })
    }

    @Test("Round trips Data and composite property-list settings exactly")
    func roundTripsDataAndCompositePropertyListValues() throws {
        let shortcutKey = "EZSelectionShortcutKey_keyHolder"
        let disabledAppsKey = "kAppModelTriggerListKey"
        let betaKey = "EZBetaFeatureKey"
        let shortcut = Data([0x00, 0x01, 0x7F, 0x80, 0xFF])
        let disabledApps: [[String: Any]] = [
            [
                "appBundleID": "com.example.editor",
                "triggerType": NSNumber(value: 2),
            ],
            [
                "appBundleID": "com.example.browser",
                "triggerType": NSNumber(value: 1),
            ],
        ]
        let source = makeService(domain: [
            shortcutKey: shortcut,
            disabledAppsKey: disabledApps,
            betaKey: NSNumber(value: true),
        ])
        let encrypted = try source.exportData(password: password, confirmation: password)
        let destinationStore = TestConfigurationDomainStore(domain: [:])
        let destination = makeService(store: destinationStore)

        let prepared = try destination.prepareRestore(data: encrypted, password: password)
        try destination.apply(prepared)

        #expect(destinationStore.domain[shortcutKey] as? Data == shortcut)
        let restoredDisabledApps = try #require(
            destinationStore.domain[disabledAppsKey] as? [[String: Any]]
        )
        #expect(NSArray(array: restoredDisabledApps).isEqual(to: disabledApps))
        let restoredBeta = try #require(destinationStore.domain[betaKey] as? NSNumber)
        #expect(CFGetTypeID(restoredBeta) == CFBooleanGetTypeID())
        #expect(restoredBeta.boolValue)
    }

    @Test("Previews and applies a merge without deleting current-only values")
    func previewsAndAppliesMergeOverlay() throws {
        let service = ServiceType.customOpenAI.rawValue
        let endpointKey = "EZ\(service)EndPointKey"
        let source = makeService(domain: [
            "EZConfiguration_kApperanceKey": NSNumber(value: 2),
            "maxWindowHeightPercentage": 80,
            "EZDeepLAuthKey": "FAKE_IMPORTED_CREDENTIAL",
            endpointKey: "https://api.example.com/v1",
        ])
        let encrypted = try source.exportData(password: password, confirmation: password)

        let destinationStore = TestConfigurationDomainStore(domain: [
            "EZConfiguration_kApperanceKey": NSNumber(value: 0),
            "EZDeepLAuthKey": "FAKE_CURRENT_CREDENTIAL",
            "EZConfiguration_kQueryHistory": ["current history remains"],
            "future.current-only.key": "preserve me",
        ])
        let destination = makeService(store: destinationStore)
        let prepared = try destination.prepareRestore(data: encrypted, password: password)

        #expect(prepared.preview.settingCount == 3)
        #expect(prepared.preview.credentialCount == 1)
        #expect(prepared.preview.newCount == 2)
        #expect(prepared.preview.overwriteCount == 2)
        #expect(prepared.preview.skippedUnsafeEndpointCount == 0)

        try destination.apply(prepared)

        #expect(
            (destinationStore.domain["EZConfiguration_kApperanceKey"] as? NSNumber)?.intValue == 2
        )
        #expect((destinationStore.domain["maxWindowHeightPercentage"] as? NSNumber)?.intValue == 80)
        #expect(destinationStore.domain["EZDeepLAuthKey"] as? String == "FAKE_IMPORTED_CREDENTIAL")
        #expect(destinationStore.domain[endpointKey] as? String == "https://api.example.com/v1")
        #expect(
            destinationStore.domain["EZConfiguration_kQueryHistory"] as? [String] ==
                ["current history remains"]
        )
        #expect(destinationStore.domain["future.current-only.key"] as? String == "preserve me")
    }

    @Test("Skips an unsafe imported endpoint while restoring the remaining service settings")
    func skipsUnsafeEndpointDuringPreview() throws {
        let service = ServiceType.customOpenAI.rawValue
        let endpointKey = "EZ\(service)EndPointKey"
        let source = makeService(domain: [
            endpointKey: "http://api.example.com/v1",
            "maxWindowHeightPercentage": 70,
        ])
        let encrypted = try source.exportData(password: password, confirmation: password)
        let destinationStore = TestConfigurationDomainStore(domain: [:])
        let destination = makeService(store: destinationStore)

        let prepared = try destination.prepareRestore(data: encrypted, password: password)

        #expect(prepared.preview.settingCount == 2)
        #expect(prepared.preview.newCount == 1)
        #expect(prepared.preview.overwriteCount == 0)
        #expect(prepared.preview.skippedUnsafeEndpointCount == 1)

        try destination.apply(prepared)
        #expect(destinationStore.domain[endpointKey] == nil)
        #expect((destinationStore.domain["maxWindowHeightPercentage"] as? NSNumber)?.intValue == 70)
    }

    @Test("Merges imported service order without removing current-only services")
    func mergesServiceOrderAsStableUnion() throws {
        let importedService = "\(ServiceType.customOpenAI.rawValue)#00000000-0000-4000-8000-000000000004"
        let orderKey = "kAllServiceTypesKey-1"
        let source = makeService(domain: [
            orderKey: [ServiceType.youdao.rawValue, importedService],
        ])
        let encrypted = try source.exportData(password: password, confirmation: password)
        let destinationStore = TestConfigurationDomainStore(domain: [
            orderKey: [ServiceType.google.rawValue, ServiceType.youdao.rawValue],
        ])
        let destination = makeService(store: destinationStore)

        let prepared = try destination.prepareRestore(data: encrypted, password: password)
        try destination.apply(prepared)

        #expect(
            destinationStore.domain[orderKey] as? [String] == [
                ServiceType.google.rawValue,
                ServiceType.youdao.rawValue,
                importedService,
            ]
        )
    }

    @Test("Rejects duplicate and unsupported semantic descriptors")
    func rejectsAmbiguousPayloadItems() throws {
        let appearance = backupItem(
            descriptor: .init(name: "setting.appearance"),
            value: NSNumber(value: 2)
        )
        let duplicatePayload = makePayload(items: [appearance, appearance])
        let unsupportedPayload = makePayload(items: [
            backupItem(
                descriptor: .init(name: "future.unsupported.descriptor"),
                value: "value"
            ),
        ])
        let destination = makeService(domain: [:])

        #expect(throws: ConfigurationBackupError.duplicateItem) {
            try destination.prepareRestore(
                data: try encrypt(duplicatePayload),
                password: password
            )
        }
        #expect(throws: ConfigurationBackupError.unsupportedDescriptor) {
            try destination.prepareRestore(
                data: try encrypt(unsupportedPayload),
                password: password
            )
        }
    }

    @Test("Rejects mismatched value kinds and wrong application metadata")
    func rejectsInvalidPayloadSemantics() throws {
        let invalidValuePayload = makePayload(items: [
            ConfigurationBackupItem(
                descriptor: .init(name: "setting.appearance"),
                valueKind: .string,
                value: try encodeValue(1)
            ),
        ])
        let wrongApplicationPayload = ConfigurationBackupPayload(
            schemaVersion: ConfigurationBackupPayload.schemaVersion,
            bundleIdentifier: "com.example.different-application",
            applicationVersion: "1.0",
            applicationBuild: "100",
            createdAt: fixedDate,
            items: []
        )
        let destination = makeService(domain: [:])

        #expect(throws: ConfigurationBackupError.invalidValue) {
            try destination.prepareRestore(
                data: try encrypt(invalidValuePayload),
                password: password
            )
        }
        #expect(throws: ConfigurationBackupError.wrongApplication) {
            try destination.prepareRestore(
                data: try encrypt(wrongApplicationPayload),
                password: password
            )
        }
    }

    @Test("Rolls back the complete domain when write verification fails")
    func rollsBackFailedWriteVerification() throws {
        let source = makeService(domain: ["maxWindowHeightPercentage": 60])
        let encrypted = try source.exportData(password: password, confirmation: password)
        let oldDomain: [String: Any] = [
            "maxWindowHeightPercentage": 100,
            "future.current-only.key": "preserve me",
        ]
        let destinationStore = TestConfigurationDomainStore(
            domain: oldDomain,
            writeBehavior: .dropFirstWrite(key: "maxWindowHeightPercentage")
        )
        let destination = makeService(store: destinationStore)
        let prepared = try destination.prepareRestore(data: encrypted, password: password)

        #expect(throws: ConfigurationBackupError.writeFailed) {
            try destination.apply(prepared)
        }
        #expect(destinationStore.setCount == 2)
        #expect(NSDictionary(dictionary: destinationStore.domain).isEqual(to: oldDomain))
    }

    @Test("Reports rollback failure when the original domain cannot be restored")
    func reportsRollbackFailure() throws {
        let source = makeService(domain: ["maxWindowHeightPercentage": 60])
        let encrypted = try source.exportData(password: password, confirmation: password)
        let destinationStore = TestConfigurationDomainStore(
            domain: ["future.current-only.key": "preserve me"],
            writeBehavior: .corruptEveryWrite
        )
        let destination = makeService(store: destinationStore)
        let prepared = try destination.prepareRestore(data: encrypted, password: password)

        #expect(throws: ConfigurationBackupError.rollbackFailed) {
            try destination.apply(prepared)
        }
        #expect(destinationStore.setCount == 2)
    }

    @Test("Writes only encrypted bytes with owner-only file permissions")
    func writesEncryptedOwnerOnlyBackupFile() throws {
        let credentialCanary = "FAKE_FILE_CREDENTIAL_MUST_NOT_APPEAR"
        let service = makeService(domain: ["EZDeepLAuthKey": credentialCanary])
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("easydictbackup")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.writeBackup(
            password: password,
            confirmation: password,
            to: url,
            now: fixedDate
        )

        let data = try service.readBackup(at: url)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
        #expect(data.range(of: Data(credentialCanary.utf8)) == nil)
        let payload = try ConfigurationBackupCodec.decrypt(data, password: password)
        #expect(payload.items.count == 1)
        #expect(payload.items.first?.descriptor.name == "credential.deepl.auth")
    }

    @Test("Atomically replaces an existing backup with owner-only encrypted data")
    func replacesExistingBackupFileSecurely() throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: directoryURL) }

        let url = directoryURL.appendingPathComponent("Existing.easydictbackup")
        let plaintextCanary = "PLAINTEXT_EXISTING_BACKUP_MUST_DISAPPEAR"
        let oldData = Data(plaintextCanary.utf8)
        try oldData.write(to: url)
        try fileManager.setAttributes(
            [.posixPermissions: NSNumber(value: 0o644)],
            ofItemAtPath: url.path
        )
        let oldAttributes = try fileManager.attributesOfItem(atPath: url.path)
        #expect((oldAttributes[.posixPermissions] as? NSNumber)?.intValue == 0o644)
        let temporaryFilesBefore = try backupTemporaryFiles(in: directoryURL)

        let service = makeService(domain: [
            "EZConfiguration_kApperanceKey": NSNumber(value: 2),
        ])
        try service.writeBackup(
            password: password,
            confirmation: password,
            to: url,
            now: fixedDate
        )

        let encryptedData = try service.readBackup(at: url)
        let finalAttributes = try fileManager.attributesOfItem(atPath: url.path)
        let temporaryFilesAfter = try backupTemporaryFiles(in: directoryURL)
        #expect(encryptedData != oldData)
        #expect(encryptedData.range(of: Data(plaintextCanary.utf8)) == nil)
        #expect((finalAttributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
        #expect(temporaryFilesAfter == temporaryFilesBefore)

        let payload = try ConfigurationBackupCodec.decrypt(encryptedData, password: password)
        #expect(payload.createdAt == fixedDate)
        #expect(payload.items.count == 1)
        #expect(payload.items.first?.descriptor.name == "setting.appearance")
    }

    // MARK: Private

    private let password = "correct horse battery staple"
    private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
    private let metadata = ConfigurationBackupApplicationMetadata(
        bundleIdentifier: "com.example.easydict-tests",
        version: "1.0",
        build: "100"
    )

    private func makeService(domain: [String: Any]) -> ConfigurationBackupService {
        makeService(store: TestConfigurationDomainStore(domain: domain))
    }

    private func makeService(
        store: TestConfigurationDomainStore
    )
        -> ConfigurationBackupService {
        ConfigurationBackupService(domainStore: store, metadata: metadata)
    }

    private func makePayload(items: [ConfigurationBackupItem]) -> ConfigurationBackupPayload {
        ConfigurationBackupPayload(
            schemaVersion: ConfigurationBackupPayload.schemaVersion,
            bundleIdentifier: metadata.bundleIdentifier,
            applicationVersion: metadata.version,
            applicationBuild: metadata.build,
            createdAt: fixedDate,
            items: items
        )
    }

    private func backupItem(
        descriptor: ConfigurationItemDescriptor,
        value: Any
    )
        -> ConfigurationBackupItem {
        let valueKind = ConfigurationValueKind.detect(value) ?? .data
        return ConfigurationBackupItem(
            descriptor: descriptor,
            valueKind: valueKind,
            value: (try? encodeValue(value)) ?? Data()
        )
    }

    private func encodeValue(_ value: Any) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: ["value": value],
            format: .binary,
            options: 0
        )
    }

    private func encrypt(_ payload: ConfigurationBackupPayload) throws -> Data {
        try ConfigurationBackupCodec.encrypt(
            payload,
            password: password,
            salt: Data((0 ..< ConfigurationBackupCodec.saltLength).map(UInt8.init)),
            nonce: Data((0 ..< ConfigurationBackupCodec.nonceLength).map { UInt8($0 + 80) })
        )
    }

    private func backupTemporaryFiles(in directoryURL: URL) throws -> Set<String> {
        let filenames = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
        return Set(filenames.filter {
            $0.hasPrefix(".easydict-backup-") && $0.hasSuffix(".tmp")
        })
    }
}

// MARK: - TestConfigurationDomainStore

/// In-memory domain store that can deterministically simulate verification and rollback failures.
private final class TestConfigurationDomainStore: ConfigurationDomainStoring {
    // MARK: Lifecycle

    init(
        domain: [String: Any],
        writeBehavior: WriteBehavior = .normal
    ) {
        self.domain = domain
        self.writeBehavior = writeBehavior
    }

    // MARK: Internal

    enum WriteBehavior {
        case normal
        case dropFirstWrite(key: String)
        case corruptEveryWrite
    }

    private(set) var domain: [String: Any]
    private(set) var setCount = 0

    func persistentDomain() -> [String: Any] {
        domain
    }

    func setPersistentDomain(_ domain: [String: Any]) {
        setCount += 1
        switch writeBehavior {
        case .normal:
            self.domain = domain
        case let .dropFirstWrite(key) where setCount == 1:
            self.domain = domain
            self.domain.removeValue(forKey: key)
        case .dropFirstWrite:
            self.domain = domain
        case .corruptEveryWrite:
            self.domain = [:]
        }
    }

    // MARK: Private

    private let writeBehavior: WriteBehavior
}
