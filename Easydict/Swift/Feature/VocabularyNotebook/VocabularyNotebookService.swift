//
//  VocabularyNotebookService.swift
//  Easydict
//
//  Created by izual on 2026/9/15.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - VocabularyNotebookService

/// Appends completed query results to the local `words.jsonl` file consumed by an
/// external review program and synced via Syncthing.
///
/// The service is view-free: write failures are surfaced through a
/// `Notification.Name.vocabularyNotebookWriteFailed` notification instead of an
/// `NSAlert`, keeping the write logic decoupled from UI.
@objc(VocabularyNotebookService)
@objcMembers
final class VocabularyNotebookService: NSObject {
    // MARK: Lifecycle

    override init() {
        super.init()
    }

    // MARK: Internal

    static let shared = VocabularyNotebookService()

    /// Appends one query record. No-op when the feature is disabled, the directory
    /// is unset, the text is empty, or the query failed (`result.error != nil`).
    func append(queryModel: QueryModel, result: QueryResult) {
        guard Defaults[.enableVocabularyNotebook] else {
            return
        }

        guard result.error == nil else {
            return
        }

        let text = queryModel.queryText
        guard !text.isEmpty else {
            return
        }

        let directory = Defaults[.vocabularyNotebookDirectory]
        guard !directory.isEmpty else {
            return
        }

        // `result.from` / `result.to` are the resolved language pair set by
        // `prehandleQueryTextOutcome` in both the UI and HTTP query paths. Prefer them
        // over `queryModel.queryFromLanguage`, which the HTTP path does not populate.
        let sourceLanguage = result.from == .auto ? queryModel.queryFromLanguage : result.from
        let targetLanguage = result.to == .auto ? queryModel.queryTargetLanguage : result.to

        let entry = VocabularyEntry(
            text: text,
            sourceLanguage: sourceLanguage.code,
            targetLanguage: targetLanguage.code,
            translatedText: result.translatedText,
            timestamp: Date(),
            dictionaryEntry: DictionaryEntry(wordResult: result.wordResult)
        )

        appendQueue.async { [weak self] in
            guard let self else { return }
            do {
                try Self.append(entry, to: directory)
            } catch {
                logError("Failed to append vocabulary entry: \(error)")
                NotificationCenter.default.post(
                    name: .vocabularyNotebookWriteFailed,
                    object: self,
                    userInfo: [UserInfoKey.vocabularyNotebookDirectory: directory]
                )
            }
        }
    }

    // MARK: Private

    /// File name of the JSONL notebook in the selected directory.
    private static let fileName = "words.jsonl"

    /// Serializes appends so UI and HTTP writes never interleave in a single process.
    private let appendQueue = DispatchQueue(label: "com.izual.Easydict.vocabulary-notebook")

    private static func append(_ entry: VocabularyEntry, to directory: String) throws {
        let directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        let fileManager = FileManager.default

        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let fileURL = directoryURL.appendingPathComponent(fileName)
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }

        let encoder = makeEncoder()
        let data = try encoder.encode(entry)
        var line = data
        line.append(0x0A)

        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
        try handle.synchronize()
    }

    /// Builds an encoder that formats timestamps in local ISO 8601 time.
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            // DateFormatter is not thread-safe; create a fresh instance per encode.
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        return encoder
    }
}
