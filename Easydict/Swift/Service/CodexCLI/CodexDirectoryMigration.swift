//
//  CodexDirectoryMigration.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

// MARK: - CodexDirectoryMigration

/// Moves an existing managed Codex root to the current bundle-scoped location.
/// Existing destinations always win; legacy directories are never merged or overwritten.
enum CodexDirectoryMigration {
    // MARK: Internal

    static func run(
        pathManager: AppPathManager = .current,
        fileManager: FileManager = .default
    ) throws {
        try lock.withLock {
            let destination = pathManager.codexDirectory
            let sources = pathManager.legacyCodexDirectories.filter {
                itemExists(at: $0, fileManager: fileManager)
            }

            if itemExists(at: destination, fileManager: fileManager) {
                try validateManagedDirectory(destination, fileManager: fileManager)
                if !sources.isEmpty {
                    logWarn("Codex directory migration skipped because the destination and legacy data both exist")
                }
                return
            }

            guard let source = sources.first else { return }
            if sources.count > 1 {
                logWarn("Multiple legacy Codex directories found; migrating the newest layout only")
            }

            try validateManagedDirectory(source, fileManager: fileManager)
            try rejectSymbolicLinkAncestors(of: destination, fileManager: fileManager)
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )

            do {
                try fileManager.moveItem(at: source, to: destination)
            } catch {
                // Another process may have completed the same atomic move.
                guard itemExists(at: destination, fileManager: fileManager),
                      !itemExists(at: source, fileManager: fileManager)
                else { throw error }
            }

            try validateManagedDirectory(destination, fileManager: fileManager)
            logInfo("Migrated managed Codex data to the bundle-scoped codex directory")
        }
    }

    // MARK: Private

    private static let lock = NSLock()

    private static func itemExists(at url: URL, fileManager: FileManager) -> Bool {
        fileManager.fileExists(atPath: url.path)
            || (try? fileManager.destinationOfSymbolicLink(atPath: url.path)) != nil
    }

    private static func validateManagedDirectory(
        _ directory: URL,
        fileManager: FileManager
    ) throws {
        try rejectSymbolicLinkAncestors(of: directory, fileManager: fileManager)
        let values = try directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        let attributes = try fileManager.attributesOfItem(atPath: directory.path)
        guard values.isDirectory == true,
              values.isSymbolicLink != true,
              directory.resolvingSymlinksInPath() == directory.standardizedFileURL,
              let permissions = attributes[.posixPermissions] as? NSNumber,
              permissions.intValue & 0o077 == 0
        else { throw CodexManagedError.externalConfiguration }
    }

    private static func rejectSymbolicLinkAncestors(
        of directory: URL,
        fileManager: FileManager
    ) throws {
        var ancestor = directory
        while true {
            if (try? fileManager.destinationOfSymbolicLink(atPath: ancestor.path)) != nil {
                throw CodexManagedError.externalConfiguration
            }
            if ancestor.path == "/" { return }
            ancestor.deleteLastPathComponent()
        }
    }
}
