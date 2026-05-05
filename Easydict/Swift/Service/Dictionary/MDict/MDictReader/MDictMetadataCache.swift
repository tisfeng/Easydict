//
//  MDictMetadataCache.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/04.
//  Copyright © 2026 izual. All rights reserved.
//

import CryptoKit
import Foundation

// MARK: - MDictCachedMetadata

/// Lightweight reader metadata that can be reused between launches.
///
/// The cache stores only structural index data derived from the MDX or MDD
/// file. Definitions, resources, decompressed blocks, and rendered HTML stay
/// outside this persistent cache so stale data cannot leak into query results.
struct MDictCachedMetadata: Codable {
    let header: MDictHeader
    let keyBlockRanges: [MDictKeyBlockRange]
    let recordBlockRanges: [RecordBlockRange]
    let entryCount: Int
}

// MARK: - MDictMetadataCache

/// Disk cache for MDict reader metadata.
///
/// Cache entries are invalidated by file path, byte size, and modification
/// time. A miss simply falls back to normal parsing, so cache failures affect
/// startup latency but not dictionary correctness.
final class MDictMetadataCache {
    // MARK: Lifecycle

    private init() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.izual.Easydict"
        let baseURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.cacheDirectory = baseURL
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("mdict-metadata-cache", isDirectory: true)
    }

    // MARK: Internal

    static let shared = MDictMetadataCache()

    func load(for fileURL: URL) -> MDictCachedMetadata? {
        guard let signature = fileSignature(for: fileURL) else { return nil }
        let cacheURL = cacheURL(for: fileURL)
        guard let data = try? Data(contentsOf: cacheURL),
              let entry = try? decoder.decode(CacheEntry.self, from: data),
              entry.signature == signature
        else { return nil }

        return entry.metadata
    }

    func save(_ metadata: MDictCachedMetadata, for fileURL: URL) {
        guard let signature = fileSignature(for: fileURL) else { return }
        do {
            try fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
            let entry = CacheEntry(
                schemaVersion: Self.schemaVersion,
                signature: signature,
                metadata: metadata
            )
            let data = try encoder.encode(entry)
            try data.write(to: cacheURL(for: fileURL), options: .atomic)
        } catch {
            logError("MDictMetadataCache: failed to save \(fileURL.path): \(error)")
        }
    }

    // MARK: Private

    private struct CacheEntry: Codable {
        let schemaVersion: Int
        let signature: FileSignature
        let metadata: MDictCachedMetadata
    }

    private struct FileSignature: Codable, Equatable {
        let schemaVersion: Int
        let path: String
        let fileSize: UInt64
        let modificationTime: TimeInterval
    }

    private static let schemaVersion = 1

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    private func cacheURL(for fileURL: URL) -> URL {
        let digest = SHA256.hash(data: Data(fileURL.standardizedFileURL.path.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(name).appendingPathExtension("json")
    }

    private func fileSignature(for fileURL: URL) -> FileSignature? {
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .fileSizeKey,
                .contentModificationDateKey,
            ])
            guard let fileSize = values.fileSize,
                  let modificationDate = values.contentModificationDate
            else { return nil }

            return FileSignature(
                schemaVersion: Self.schemaVersion,
                path: fileURL.standardizedFileURL.path,
                fileSize: UInt64(fileSize),
                modificationTime: modificationDate.timeIntervalSince1970
            )
        } catch {
            return nil
        }
    }
}
