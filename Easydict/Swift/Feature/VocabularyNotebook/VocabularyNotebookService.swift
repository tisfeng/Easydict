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

        // `result.queryText` is captured during query preprocessing. `queryModel` is
        // shared with the UI and its text can change while this result is still
        // completing, which would pair a newer input with the current result.
        let text = result.queryText
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

    /// Blocks until all previously queued appends have been written to disk.
    ///
    /// Called from `applicationWillTerminate` so a query that completes right before
    /// the app quits is still persisted instead of being dropped with the process.
    func flush() {
        appendQueue.sync {}
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

        let handle = try FileHandle(forUpdating: fileURL)
        defer { try? handle.close() }
        let endOffset = try handle.seekToEnd()
        // A file written by another tool may not end with a newline; insert one so the
        // appended record stays on its own JSONL line instead of concatenating with the
        // previous one.
        if endOffset > 0 {
            try handle.seek(toOffset: endOffset - 1)
            let lastByte = try handle.read(upToCount: 1)
            try handle.seekToEnd()
            if lastByte != Data([0x0A]) {
                try handle.write(contentsOf: Data([0x0A]))
            }
        }
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
