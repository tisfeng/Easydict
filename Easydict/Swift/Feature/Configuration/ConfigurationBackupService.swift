//
//  ConfigurationBackupService.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ConfigurationBackupApplicationMetadata

struct ConfigurationBackupApplicationMetadata {
    static var current: ConfigurationBackupApplicationMetadata {
        let info = Bundle.main.infoDictionary ?? [:]
        return ConfigurationBackupApplicationMetadata(
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.izual.Easydict",
            version: info["CFBundleShortVersionString"] as? String ?? "unknown",
            build: info["CFBundleVersion"] as? String ?? "unknown"
        )
    }

    let bundleIdentifier: String
    let version: String
    let build: String
}

// MARK: - ConfigurationDomainStoring

protocol ConfigurationDomainStoring {
    func persistentDomain() -> [String: Any]
    func setPersistentDomain(_ domain: [String: Any])
}

// MARK: - UserDefaultsConfigurationDomainStore

struct UserDefaultsConfigurationDomainStore: ConfigurationDomainStoring {
    let defaults: UserDefaults
    let domainName: String

    func persistentDomain() -> [String: Any] {
        defaults.persistentDomain(forName: domainName) ?? [:]
    }

    func setPersistentDomain(_ domain: [String: Any]) {
        defaults.setPersistentDomain(domain, forName: domainName)
    }
}

// MARK: - ConfigurationBackupService

/// Builds semantic backups and applies validated restore overlays transactionally.
final class ConfigurationBackupService {
    // MARK: Lifecycle

    init(
        domainStore: ConfigurationDomainStoring? = nil,
        metadata: ConfigurationBackupApplicationMetadata = .current
    ) {
        self.metadata = metadata
        self.domainStore = domainStore ?? UserDefaultsConfigurationDomainStore(
            defaults: .standard,
            domainName: metadata.bundleIdentifier
        )
    }

    // MARK: Internal

    static let minimumPasswordLength = 12

    static func suggestedFilename(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "Easydict Configuration \(formatter.string(from: now)).easydictbackup"
    }

    func exportData(password: String, confirmation: String, now: Date = Date()) throws -> Data {
        guard password.count >= Self.minimumPasswordLength else {
            throw ConfigurationBackupError.passwordTooShort
        }
        guard password == confirmation else {
            throw ConfigurationBackupError.passwordMismatch
        }
        return try ConfigurationBackupCodec.encrypt(makePayload(now: now), password: password)
    }

    func writeBackup(
        password: String,
        confirmation: String,
        to url: URL,
        now: Date = Date()
    ) throws {
        let data = try exportData(password: password, confirmation: confirmation, now: now)
        let fileManager = FileManager.default
        let directoryURL = url.deletingLastPathComponent()
        let temporaryURL = directoryURL.appendingPathComponent(
            ".easydict-backup-\(UUID().uuidString).tmp",
            isDirectory: false
        )
        var shouldRemoveTemporaryFile = true
        defer {
            if shouldRemoveTemporaryFile {
                try? fileManager.removeItem(at: temporaryURL)
            }
        }

        do {
            guard fileManager.createFile(
                atPath: temporaryURL.path,
                contents: data,
                attributes: [.posixPermissions: NSNumber(value: 0o600)]
            ) else {
                throw ConfigurationBackupError.fileAccessFailed
            }
            let temporaryAttributes = try fileManager.attributesOfItem(atPath: temporaryURL.path)
            guard (temporaryAttributes[.posixPermissions] as? NSNumber)?.intValue == 0o600 else {
                throw ConfigurationBackupError.fileAccessFailed
            }

            if fileManager.fileExists(atPath: url.path) {
                _ = try fileManager.replaceItemAt(
                    url,
                    withItemAt: temporaryURL,
                    backupItemName: nil,
                    options: .usingNewMetadataOnly
                )
            } else {
                try fileManager.moveItem(at: temporaryURL, to: url)
            }
            shouldRemoveTemporaryFile = false

            let finalAttributes = try fileManager.attributesOfItem(atPath: url.path)
            guard (finalAttributes[.posixPermissions] as? NSNumber)?.intValue == 0o600 else {
                throw ConfigurationBackupError.fileAccessFailed
            }
        } catch let error as ConfigurationBackupError {
            throw error
        } catch {
            throw ConfigurationBackupError.fileAccessFailed
        }
    }

    func readBackup(at url: URL) throws -> Data {
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true else { throw ConfigurationBackupError.fileAccessFailed }
            if let size = values.fileSize, size > ConfigurationBackupCodec.maximumFileSize {
                throw ConfigurationBackupError.fileTooLarge
            }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard data.count <= ConfigurationBackupCodec.maximumFileSize else {
                throw ConfigurationBackupError.fileTooLarge
            }
            return data
        } catch let error as ConfigurationBackupError {
            throw error
        } catch {
            throw ConfigurationBackupError.fileAccessFailed
        }
    }

    func prepareRestore(data: Data, password: String) throws -> PreparedConfigurationRestore {
        let payload = try ConfigurationBackupCodec.decrypt(data, password: password)
        guard payload.schemaVersion == ConfigurationBackupPayload.schemaVersion else {
            throw ConfigurationBackupError.unsupportedVersion
        }
        guard payload.bundleIdentifier == metadata.bundleIdentifier else {
            throw ConfigurationBackupError.wrongApplication
        }
        guard !payload.applicationVersion.isEmpty, !payload.applicationBuild.isEmpty else {
            throw ConfigurationBackupError.invalidPayload
        }

        let currentDomain = domainStore.persistentDomain()
        var seenDescriptors = Set<ConfigurationItemDescriptor>()
        var seenKeys = Set<String>()
        var resolvedItems = [ResolvedConfigurationBackupItem]()
        var settingCount = 0
        var credentialCount = 0
        var newCount = 0
        var overwriteCount = 0
        var skippedUnsafeEndpointCount = 0

        for item in payload.items {
            guard seenDescriptors.insert(item.descriptor).inserted else {
                throw ConfigurationBackupError.duplicateItem
            }
            guard let entry = ConfigurationItemRegistry.entry(for: item.descriptor),
                  seenKeys.insert(entry.userDefaultsKey).inserted
            else {
                throw ConfigurationBackupError.unsupportedDescriptor
            }
            let value = try decodeValue(item.value)
            guard ConfigurationValueKind.detect(value) == item.valueKind, entry.accepts(value) else {
                throw ConfigurationBackupError.invalidValue
            }
            if entry.userDefaultsKey.hasPrefix("kAllServiceTypesKey-") {
                guard let serviceIdentifiers = value as? [String],
                      serviceIdentifiers.allSatisfy({
                          QueryServiceFactory.shared.metadata(withTypeId: $0) != nil
                      })
                else { throw ConfigurationBackupError.invalidValue }
            }

            switch entry.category {
            case .portableSetting:
                settingCount += 1
            case .serviceCredential:
                credentialCount += 1
            default:
                throw ConfigurationBackupError.unsupportedDescriptor
            }

            if entry.isEndpoint {
                guard let endpoint = value as? String else {
                    throw ConfigurationBackupError.invalidValue
                }
                if !endpoint.isEmpty, !ServiceEndpointSecurityPolicy.allows(endpoint) {
                    skippedUnsafeEndpointCount += 1
                    continue
                }
            }

            if currentDomain[entry.userDefaultsKey] == nil {
                newCount += 1
            } else {
                overwriteCount += 1
            }
            resolvedItems.append(.init(entry: entry, value: value))
        }

        return PreparedConfigurationRestore(
            preview: .init(
                settingCount: settingCount,
                credentialCount: credentialCount,
                newCount: newCount,
                overwriteCount: overwriteCount,
                skippedUnsafeEndpointCount: skippedUnsafeEndpointCount
            ),
            createdAt: payload.createdAt,
            resolvedItems: resolvedItems
        )
    }

    func apply(_ preparedRestore: PreparedConfigurationRestore) throws {
        let oldDomain = domainStore.persistentDomain()
        var overlay = oldDomain
        var expectedValues = [String: Any]()
        for item in preparedRestore.resolvedItems {
            let value = mergedValue(for: item, currentDomain: overlay)
            overlay[item.entry.userDefaultsKey] = value
            expectedValues[item.entry.userDefaultsKey] = value
        }

        domainStore.setPersistentDomain(overlay)
        let writtenDomain = domainStore.persistentDomain()
        let verified = expectedValues.allSatisfy { key, expectedValue in
            guard let writtenValue = writtenDomain[key] else { return false }
            return propertyListValuesEqual(writtenValue, expectedValue)
        }
        guard verified else {
            domainStore.setPersistentDomain(oldDomain)
            guard domainsEqual(domainStore.persistentDomain(), oldDomain) else {
                throw ConfigurationBackupError.rollbackFailed
            }
            throw ConfigurationBackupError.writeFailed
        }
    }

    // MARK: Private

    private let domainStore: ConfigurationDomainStoring
    private let metadata: ConfigurationBackupApplicationMetadata

    private func makePayload(now: Date) throws -> ConfigurationBackupPayload {
        var items = [ConfigurationBackupItem]()
        var seenDescriptors = Set<ConfigurationItemDescriptor>()
        let domain = domainStore.persistentDomain()
        for key in domain.keys.sorted() {
            guard let value = domain[key],
                  let entry = ConfigurationItemRegistry.entry(forUserDefaultsKey: key),
                  [.portableSetting, .serviceCredential].contains(entry.category),
                  entry.accepts(value),
                  let valueKind = ConfigurationValueKind.detect(value),
                  seenDescriptors.insert(entry.descriptor).inserted
            else { continue }
            items.append(
                ConfigurationBackupItem(
                    descriptor: entry.descriptor,
                    valueKind: valueKind,
                    value: try encodeValue(value)
                )
            )
        }
        return ConfigurationBackupPayload(
            schemaVersion: ConfigurationBackupPayload.schemaVersion,
            bundleIdentifier: metadata.bundleIdentifier,
            applicationVersion: metadata.version,
            applicationBuild: metadata.build,
            createdAt: now,
            items: items
        )
    }

    private func encodeValue(_ value: Any) throws -> Data {
        do {
            return try PropertyListSerialization.data(
                fromPropertyList: ["value": value],
                format: .binary,
                options: 0
            )
        } catch {
            throw ConfigurationBackupError.invalidValue
        }
    }

    private func decodeValue(_ data: Data) throws -> Any {
        guard data.count <= ConfigurationBackupCodec.maximumFileSize,
              let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let wrapper = object as? [String: Any],
              Set(wrapper.keys) == ["value"],
              let value = wrapper["value"], ConfigurationValueKind.detect(value) != nil
        else { throw ConfigurationBackupError.invalidValue }
        return value
    }

    private func propertyListValuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        NSDictionary(dictionary: ["value": lhs]).isEqual(to: ["value": rhs])
    }

    private func mergedValue(
        for item: ResolvedConfigurationBackupItem,
        currentDomain: [String: Any]
    )
        -> Any {
        guard item.entry.userDefaultsKey.hasPrefix("kAllServiceTypesKey-"),
              let importedOrder = item.value as? [String]
        else { return item.value }
        let currentOrder = currentDomain[item.entry.userDefaultsKey] as? [String] ?? []
        var seen = Set(currentOrder)
        return currentOrder + importedOrder.filter { seen.insert($0).inserted }
    }

    private func domainsEqual(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        NSDictionary(dictionary: lhs).isEqual(to: rhs)
    }
}
