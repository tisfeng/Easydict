//
//  AppleDictionaryTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/16.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - AppleDictionaryTests

@Suite("Apple Dictionary", .tags(.apple, .unit))
struct AppleDictionaryTests {
    // MARK: Internal

    @Test("Ignores unavailable dictionary names")
    func ignoresUnavailableDictionaryNames() {
        let service = AppleDictionary(dictionaryNames: ["com.easydict.missing-dictionary"])

        #expect(service.appleDictionaryNames.isEmpty)
    }

    @Test("Handles dictionaries without a resource URL")
    func handlesDictionaryWithoutResourceURL() {
        let service = AppleDictionary(dictionaryNames: [])

        let html = service.queryAllIframeHTMLResult(
            ofWord: "test",
            fromToLanguages: nil,
            inDictionaries: [MissingURLDictionary()]
        )

        #expect(html?.contains("Dictionary definition") == true)
    }

    @Test("Embeds local dictionary audio", arguments: [false, true])
    func embedsLocalDictionaryAudio(absolute: Bool) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let contents = directory.appendingPathComponent("Test.dictionary/Contents")
        let resources = contents.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

        for root in [contents, resources] {
            let audio = root.appendingPathComponent("exam__gb_1.ogg")
            let data = Data("dictionary pronunciation".utf8)
            try data.write(to: audio)
            defer { try? FileManager.default.removeItem(at: audio) }
            let path = absolute ? audio.path : audio.lastPathComponent
            let dataURL = "data:audio/ogg;base64,\(data.base64EncodedString())"
            let html = try renderAudio(path: path, contents: contents)

            #expect(html.contains("new Audio('\(dataURL)').play()"))
            #expect(html.contains("<audio src=\"\(dataURL)\""))
        }
    }

    @Test("Rejects audio outside dictionary contents and URL schemes")
    func rejectsUnsafeAudioPaths() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let contents = directory.appendingPathComponent("Test.dictionary/Contents")
        let sibling = directory.appendingPathComponent("Test.dictionary/Contents-other")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: true)
        let outside = sibling.appendingPathComponent("exam.ogg")
        let inside = contents.appendingPathComponent("exam.ogg")
        try Data("outside audio".utf8).write(to: outside)
        try Data("inside audio".utf8).write(to: inside)
        let symlink = contents.appendingPathComponent("escaped.ogg")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: outside)

        let paths = [
            outside.path,
            contents.path + "/../Contents-other/exam.ogg",
            "../Contents-other/exam.ogg",
            symlink.path,
            symlink.lastPathComponent,
            "/" + inside.path,
            inside.absoluteString,
            "https://example.com/exam.ogg",
            contents.path,
        ]
        for path in paths {
            let html = try renderAudio(path: path, contents: contents)
            #expect(!html.contains("data:audio/"), "Rejected path: \(path)")
            #expect(html.contains("new Audio('\(path)').play()"))
        }
    }

    // MARK: Private

    private func renderAudio(path: String, contents: URL) throws -> String {
        let entryHTML = """
        <a href="javascript:new Audio('\(path)').play();">Play</a>
        <audio src="\(path)" controls></audio>
        """
        let dictionary = AudioDictionary(url: contents.deletingLastPathComponent(), html: entryHTML)
        let service = AppleDictionary(dictionaryNames: [])
        let html = service.queryAllIframeHTMLResult(
            ofWord: "test", fromToLanguages: nil, inDictionaries: [dictionary]
        )
        return try #require(html).unescapedXMLString()
    }
}

// MARK: - AudioDictionary

private final class AudioDictionary: TTTDictionary {
    // MARK: Lifecycle

    init(url: URL, html: String) {
        self.url = url
        self.entryHTML = html
        super.init()
    }

    // MARK: Internal

    override var name: String { "Audio Dictionary" }
    override var shortName: String { "Audio" }
    override var identifier: String? { "com.easydict.audio-test" }
    override var dictionaryURL: URL? { url }

    override func entries(forSearchTerm term: String) -> [TTTDictionaryEntry] {
        [StubDictionaryEntry(html: entryHTML)]
    }

    // MARK: Private

    private let url: URL
    private let entryHTML: String
}

// MARK: - MissingURLDictionary

private final class MissingURLDictionary: TTTDictionary {
    override var name: String { "Missing URL Dictionary" }
    override var shortName: String { "Missing URL" }
    override var identifier: String? { "com.easydict.missing-url" }
    override var dictionaryURL: URL? { nil }

    override func entries(forSearchTerm term: String) -> [TTTDictionaryEntry] {
        [StubDictionaryEntry()]
    }
}

// MARK: - StubDictionaryEntry

private final class StubDictionaryEntry: TTTDictionaryEntry {
    // MARK: Lifecycle

    init(html: String = "<div>Dictionary definition</div>") {
        self.entryHTML = html
        super.init()
    }

    // MARK: Internal

    override var headword: String { "test" }
    override var text: String { "Dictionary definition" }
    override var htmlWithAppCSS: String { entryHTML }

    // MARK: Private

    private let entryHTML: String
}
