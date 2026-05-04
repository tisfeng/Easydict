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
struct MDictDictionaryRecord: Codable, Defaults.Serializable, Hashable, Identifiable, Sendable {
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
        normalizePersistedRecords()
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

    func dictionariesForLookup() async -> [MDictDictionary] {
        let enabledRecords = records.filter(\.enabled)
        let enabledPaths = Set(enabledRecords.map(\.mdxPath))
        let loaded = loadedDictionaries.filter { enabledPaths.contains($0.mdxURL.path) }
        let loadedPaths = Set(loaded.map(\.mdxURL.path))
        let missingRecords = enabledRecords.filter { !loadedPaths.contains($0.mdxPath) }
        guard !missingRecords.isEmpty else { return loaded }

        let (loadedMissing, errors) = await Self.loadDictionaries(from: missingRecords)
        mergeLoadedDictionaries(loadedMissing, errors: errors)
        return loadedDictionaries.filter { enabledPaths.contains($0.mdxURL.path) }
    }

    // MARK: - Import

    /// Import an MDX dictionary or an MDD resource file.
    func importDictionary(mdxURL: URL) throws {
        switch mdxURL.pathExtension.lowercased() {
        case "mdx":
            try importMDX(mdxURL)
        case "mdd":
            try importMDD(mdxURL)
        default:
            throw MDictError.invalidFormat("Please import an MDX or MDD file")
        }
    }

    // MARK: - Remove

    func removeDictionary(at offsets: IndexSet) {
        let pathsToRemove = Set(offsets.map { records[$0].mdxPath })
        records.remove(atOffsets: offsets)
        loadedDictionaries.removeAll { pathsToRemove.contains($0.mdxURL.path) }
        for path in pathsToRemove { loadErrors.removeValue(forKey: path) }
        persist()
    }

    func removeDictionary(_ record: MDictDictionaryRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        removeDictionary(at: IndexSet(integer: index))
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

    private static func loadDictionaries(
        from records: [MDictDictionaryRecord]
    ) async
        -> ([MDictDictionary], [String: Error]) {
        await Task.detached(priority: .userInitiated) {
            var dictionaries: [MDictDictionary] = []
            var errors: [String: Error] = [:]
            for record in records {
                do {
                    let dict = try MDictDictionary(
                        mdxURL: record.mdxURL,
                        mddURLs: record.mddURLs
                    )
                    dictionaries.append(dict)
                } catch {
                    errors[record.mdxPath] = error
                    logError("MDictManager: failed to load \(record.mdxPath): \(error)")
                }
            }
            return (dictionaries, errors)
        }.value
    }

    private func importMDX(_ mdxURL: URL) throws {
        let path = mdxURL.path
        let mddURLs = discoverMDDFiles(for: mdxURL)
        if let index = records.firstIndex(where: { $0.mdxPath == path }) {
            records[index].mddPaths = mergedMDDPaths(
                records[index].mddPaths,
                with: mddURLs
            )
            loadedDictionaries.removeAll { $0.mdxURL.path == path }
            loadErrors.removeValue(forKey: path)
            persist()
            return
        }

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

    private func importMDD(_ mddURL: URL) throws {
        let mdxCandidates = matchingMDXURLs(for: mddURL)
        if let index = records.firstIndex(where: { record in
            mdxCandidates.contains { $0.path == record.mdxPath }
        }) {
            records[index].mddPaths = mergedMDDPaths(
                records[index].mddPaths,
                with: [mddURL]
            )
            loadedDictionaries.removeAll { $0.mdxURL.path == records[index].mdxPath }
            loadErrors.removeValue(forKey: records[index].mdxPath)
            persist()
            return
        }

        guard let mdxURL = mdxCandidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            throw MDictError.invalidFormat("Please import the matching MDX file first")
        }
        try importMDX(mdxURL)
    }

    private func normalizePersistedRecords() {
        var resourcesByBasePath: [String: Set<String>] = [:]
        var enabledResourceBasePaths = Set<String>()
        for record in records
            where record.enabled && record.mdxURL.pathExtension.lowercased() != "mdx" {
            enabledResourceBasePaths.insert(record.mdxURL.deletingPathExtension().path)
        }
        for record in records where record.mdxURL.pathExtension.lowercased() != "mdx" {
            for basePath in basePathCandidates(for: record.mdxURL) {
                resourcesByBasePath[basePath, default: []].insert(record.mdxPath)
                resourcesByBasePath[basePath, default: []].formUnion(record.mddPaths)
            }
        }

        var normalized: [MDictDictionaryRecord] = []
        var seenPaths = Set<String>()
        for var record in records where record.mdxURL.pathExtension.lowercased() == "mdx" {
            guard seenPaths.insert(record.mdxPath).inserted else { continue }
            let basePath = record.mdxURL.deletingPathExtension().path
            let mddPaths = resourcesByBasePath[basePath, default: []]
                .map { URL(fileURLWithPath: $0) }
            record.mddPaths = mergedMDDPaths(record.mddPaths, with: mddPaths)
            if enabledResourceBasePaths.contains(basePath) {
                record.enabled = true
            }
            normalized.append(record)
        }

        guard normalized != records else { return }
        records = normalized
        Defaults[.mdictDictionaries] = records
    }

    private func mergeLoadedDictionaries(
        _ dictionaries: [MDictDictionary],
        errors: [String: Error]
    ) {
        let replacementPaths = Set(dictionaries.map(\.mdxURL.path)).union(errors.keys)
        loadedDictionaries.removeAll { replacementPaths.contains($0.mdxURL.path) }
        for path in replacementPaths { loadErrors.removeValue(forKey: path) }
        loadedDictionaries.append(contentsOf: dictionaries)
        loadErrors.merge(errors) { _, new in new }
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
                    && isCompanionMDDName(
                        $0.deletingPathExtension().lastPathComponent,
                        for: baseName
                    )
            }
            .sorted { $0.path < $1.path }
    }

    private func isCompanionMDDName(_ resourceName: String, for baseName: String) -> Bool {
        let escapedBaseName = NSRegularExpression.escapedPattern(for: baseName)
        return resourceName.range(
            of: #"^\#(escapedBaseName)(?:\.\d+)?$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private func matchingMDXURLs(for mddURL: URL) -> [URL] {
        basePathCandidates(for: mddURL)
            .map { URL(fileURLWithPath: $0).appendingPathExtension("mdx") }
    }

    private func basePathCandidates(for url: URL) -> [String] {
        let exactURL = url.deletingPathExtension()
        var candidates = [exactURL.path]

        let name = exactURL.lastPathComponent
        if let range = name.range(of: #"\.\d+$"#, options: .regularExpression) {
            let strippedName = String(name[..<range.lowerBound])
            let strippedURL = exactURL
                .deletingLastPathComponent()
                .appendingPathComponent(strippedName)
            candidates.append(strippedURL.path)
        }

        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    private func mergedMDDPaths(_ paths: [String], with urls: [URL]) -> [String] {
        var seen = Set<String>()
        return (paths + urls.map(\.path))
            .filter { URL(fileURLWithPath: $0).pathExtension.lowercased() == "mdd" }
            .filter { seen.insert($0).inserted }
            .sorted()
    }
}
