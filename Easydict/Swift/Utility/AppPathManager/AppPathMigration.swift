//
//  AppPathMigration.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/15.
//

import Foundation

// MARK: - AppPathMigration

/// Migrates app-managed files before any subsystem starts writing to their new locations.
enum AppPathMigration {
    // MARK: Internal

    static func prepareForLaunch(
        pathManager: AppPathManager = .current,
        fileManager: FileManager = .default
    ) {
        lock.withLock {
            guard !didPrepare else { return }
            didPrepare = true

            let migrations = [
                Migration(
                    name: "app logs",
                    source: pathManager.legacyAppLogDirectory,
                    destination: pathManager.appLogDirectory
                ),
                Migration(
                    name: "audio cache",
                    source: pathManager.legacyAudioCacheDirectory,
                    destination: pathManager.audioCacheDirectory
                ),
                Migration(
                    name: "MDict metadata cache",
                    source: pathManager.legacyMDictMetadataCacheDirectory,
                    destination: pathManager.mdictMetadataCacheDirectory
                ),
            ]

            for migration in migrations {
                do {
                    guard try migrateItem(
                        from: migration.source,
                        to: migration.destination,
                        fileManager: fileManager
                    ) else { continue }
                    NSLog("[AppPathMigration] Migrated %@", migration.name)
                } catch {
                    NSLog(
                        "[AppPathMigration] Failed to migrate %@: %@",
                        migration.name,
                        String(describing: error)
                    )
                }
            }

            do {
                try prepareCacheDirectory(pathManager.cacheDirectory, fileManager: fileManager)
            } catch {
                NSLog(
                    "[AppPathMigration] Failed to prepare the cache directory: %@",
                    String(describing: error)
                )
            }
        }
    }

    // MARK: Private

    private struct Migration {
        let name: String
        let source: URL
        let destination: URL
    }

    private enum ItemKind {
        case directory
        case regularFile
        case symbolicLink
        case other
    }

    private enum MigrationError: Error {
        case sourceNotEmpty(URL)
        case symbolicLink(URL)
    }

    private static let lock = NSLock()
    private static var didPrepare = false

    /// Returns `true` when a legacy item existed and was fully migrated.
    private static func migrateItem(
        from source: URL,
        to destination: URL,
        fileManager: FileManager
    ) throws
        -> Bool {
        guard try itemKind(at: source, fileManager: fileManager) != nil else { return false }

        try validateTreeHasNoSymbolicLinks(at: source, fileManager: fileManager)
        try rejectSymbolicLinkAncestors(of: destination, fileManager: fileManager)
        if try itemKind(at: destination, fileManager: fileManager) != nil {
            try validateTreeHasNoSymbolicLinks(at: destination, fileManager: fileManager)
        }

        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if try itemKind(at: destination, fileManager: fileManager) == nil {
            do {
                try fileManager.moveItem(at: source, to: destination)
                return true
            } catch {
                let sourceKind = try itemKind(at: source, fileManager: fileManager)
                let destinationKind = try itemKind(at: destination, fileManager: fileManager)
                if sourceKind == nil, destinationKind != nil {
                    return true
                }
                guard sourceKind != nil, destinationKind != nil else { throw error }
                try validateTreeHasNoSymbolicLinks(at: destination, fileManager: fileManager)
            }
        }

        try mergeItem(from: source, to: destination, fileManager: fileManager)
        return true
    }

    private static func mergeItem(
        from source: URL,
        to destination: URL,
        fileManager: FileManager
    ) throws {
        guard let sourceKind = try itemKind(at: source, fileManager: fileManager) else { return }
        guard let destinationKind = try itemKind(at: destination, fileManager: fileManager) else {
            do {
                try fileManager.moveItem(at: source, to: destination)
            } catch {
                let currentSourceKind = try itemKind(at: source, fileManager: fileManager)
                let currentDestinationKind = try itemKind(at: destination, fileManager: fileManager)
                if currentSourceKind == nil, currentDestinationKind != nil {
                    return
                }
                guard currentSourceKind != nil, currentDestinationKind != nil else { throw error }
                try validateTreeHasNoSymbolicLinks(at: destination, fileManager: fileManager)
                try mergeItem(from: source, to: destination, fileManager: fileManager)
            }
            return
        }

        if sourceKind == .directory, destinationKind == .directory {
            let sourceChildren = try fileManager.contentsOfDirectory(
                at: source,
                includingPropertiesForKeys: nil
            )
            for sourceChild in sourceChildren {
                let destinationChild = destination.appendingPathComponent(
                    sourceChild.lastPathComponent,
                    isDirectory: false
                )
                try mergeItem(from: sourceChild, to: destinationChild, fileManager: fileManager)
            }

            guard try fileManager.contentsOfDirectory(atPath: source.path).isEmpty else {
                throw MigrationError.sourceNotEmpty(source)
            }
            try fileManager.removeItem(at: source)
            return
        }

        if sourceKind == .regularFile,
           destinationKind == .regularFile,
           fileManager.contentsEqual(atPath: source.path, andPath: destination.path) {
            try fileManager.removeItem(at: source)
            return
        }

        let conflictDestination = uniqueConflictURL(for: destination, fileManager: fileManager)
        try fileManager.moveItem(at: source, to: conflictDestination)
        NSLog(
            "[AppPathMigration] Preserved a conflicting legacy item at %@",
            conflictDestination.path
        )
    }

    private static func prepareCacheDirectory(
        _ directory: URL,
        fileManager: FileManager
    ) throws {
        try rejectSymbolicLinkAncestors(of: directory, fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        var cacheDirectory = directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try cacheDirectory.setResourceValues(resourceValues)
    }

    private static func validateTreeHasNoSymbolicLinks(
        at url: URL,
        fileManager: FileManager
    ) throws {
        guard let kind = try itemKind(at: url, fileManager: fileManager) else { return }
        guard kind != .symbolicLink else { throw MigrationError.symbolicLink(url) }
        guard kind == .directory else { return }

        for child in try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        ) {
            try validateTreeHasNoSymbolicLinks(at: child, fileManager: fileManager)
        }
    }

    private static func rejectSymbolicLinkAncestors(
        of url: URL,
        fileManager: FileManager
    ) throws {
        var ancestor = url
        while true {
            if try itemKind(at: ancestor, fileManager: fileManager) == .symbolicLink {
                throw MigrationError.symbolicLink(ancestor)
            }
            guard ancestor.path != "/" else { return }
            ancestor.deleteLastPathComponent()
        }
    }

    private static func itemKind(
        at url: URL,
        fileManager: FileManager
    ) throws
        -> ItemKind? {
        let exists = fileManager.fileExists(atPath: url.path)
            || (try? fileManager.destinationOfSymbolicLink(atPath: url.path)) != nil
        guard exists else { return nil }

        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        switch attributes[.type] as? FileAttributeType {
        case .typeDirectory:
            return .directory
        case .typeRegular:
            return .regularFile
        case .typeSymbolicLink:
            return .symbolicLink
        default:
            return .other
        }
    }

    private static func uniqueConflictURL(
        for destination: URL,
        fileManager: FileManager
    )
        -> URL {
        let pathExtension = destination.pathExtension
        let baseName = destination.deletingPathExtension().lastPathComponent

        while true {
            let conflictName = "\(baseName)-legacy-\(UUID().uuidString)"
            var candidate = destination.deletingLastPathComponent()
                .appendingPathComponent(conflictName, isDirectory: false)
            if !pathExtension.isEmpty {
                candidate.appendPathExtension(pathExtension)
            }
            let exists = fileManager.fileExists(atPath: candidate.path)
                || (try? fileManager.destinationOfSymbolicLink(atPath: candidate.path)) != nil
            if !exists {
                return candidate
            }
        }
    }
}
