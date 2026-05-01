//
//  MDictManager.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - MDictDictionaryRecord

/// A persisted reference to an imported MDict dictionary.
struct MDictDictionaryRecord: Codable, Defaults.Serializable, Hashable, Identifiable {
    let mdxPath: String
    var mddPaths: [String]
    var enabled: Bool
    var title: String

    var id: String { mdxPath }

    var mdxURL: URL { URL(fileURLWithPath: mdxPath) }
    var mddURLs: [URL] { mddPaths.map { URL(fileURLWithPath: $0) } }
}

// MARK: - Defaults.Keys

extension Defaults.Keys {
    static let mdictDictionaries = Key<[MDictDictionaryRecord]>(
        "MDictManager_importedDictionaries",
        default: []
    )
}

// MARK: - MDictManager

/// Singleton that manages imported MDict dictionaries and their lifecycle.
///
/// Persists dictionary records via `Defaults` and loads live `MDictDictionary`
/// instances on demand. Notifies observers via `NotificationCenter` when the
/// dictionary list changes.
@MainActor
final class MDictManager: ObservableObject {
    // MARK: Lifecycle

    private init() {
        self.records = Defaults[.mdictDictionaries]
        loadDictionaries()
    }

    // MARK: Internal

    static let shared = MDictManager()

    static let didChangeNotification = Notification.Name("MDictManagerDidChange")

    @Published private(set) var records: [MDictDictionaryRecord]
    @Published private(set) var loadedDictionaries: [MDictDictionary] = []
    @Published private(set) var loadErrors: [String: Error] = [:]

    var enabledDictionaries: [MDictDictionary] {
        let enabledPaths = Set(records.filter(\.enabled).map(\.mdxPath))
        return loadedDictionaries.filter { enabledPaths.contains($0.mdxURL.path) }
    }

    // MARK: - Import

    /// Import an MDX file, automatically discovering sibling MDD files.
    func importDictionary(mdxURL: URL) throws {
        let path = mdxURL.path
        guard !records.contains(where: { $0.mdxPath == path }) else { return }

        let mddURLs = discoverMDDFiles(for: mdxURL)
        let dict = try MDictDictionary(mdxURL: mdxURL, mddURLs: mddURLs)

        let record = MDictDictionaryRecord(
            mdxPath: path,
            mddPaths: mddURLs.map(\.path),
            enabled: true,
            title: dict.title
        )
        records.append(record)
        loadedDictionaries.append(dict)
        persist()
    }

    // MARK: - Remove

    func removeDictionary(at offsets: IndexSet) {
        let pathsToRemove = Set(offsets.map { records[$0].mdxPath })
        records.remove(atOffsets: offsets)
        loadedDictionaries.removeAll { pathsToRemove.contains($0.mdxURL.path) }
        for path in pathsToRemove { loadErrors.removeValue(forKey: path) }
        persist()
    }

    // MARK: - Enable / Disable

    func setEnabled(_ enabled: Bool, for record: MDictDictionaryRecord) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx].enabled = enabled
        persist()
    }

    // MARK: - Reorder

    func moveDictionary(from source: IndexSet, to destination: Int) {
        records.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    // MARK: Private

    private func loadDictionaries() {
        loadedDictionaries = []
        loadErrors = [:]
        for record in records {
            do {
                let dict = try MDictDictionary(
                    mdxURL: record.mdxURL,
                    mddURLs: record.mddURLs
                )
                loadedDictionaries.append(dict)
            } catch {
                loadErrors[record.mdxPath] = error
                logError("MDictManager: failed to load \(record.mdxPath): \(error)")
            }
        }
    }

    private func persist() {
        Defaults[.mdictDictionaries] = records
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    /// Find MDD files in the same directory as the MDX file with the same base name.
    private func discoverMDDFiles(for mdxURL: URL) -> [URL] {
        let dir = mdxURL.deletingLastPathComponent()
        let baseName = mdxURL.deletingPathExtension().lastPathComponent
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return contents
            .filter {
                $0.pathExtension.lowercased() == "mdd"
                    && $0.deletingPathExtension().lastPathComponent
                    .lowercased()
                    .hasPrefix(baseName.lowercased())
            }
            .sorted { $0.path < $1.path }
    }
}
