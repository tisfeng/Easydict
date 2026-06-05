//
//  MDictReaderTests.swift
//  EasydictTests
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - MDictReaderTests

/// Tests for the MDict binary format parser utilities (decompression, binary reading, key index).
@Suite("MDict Reader", .tags(.unit))
struct MDictReaderTests {
    // MARK: Internal

    // MARK: - Header attribute extraction

    @Test("Extract attribute from XML-like header text")
    func testExtractAttribute() {
        let header = """
        <Dictionary GeneratedByEngineVersion="2.0" Format="Html" \
        KeyCaseSensitive="No" Encoding="utf-8" Title="Test Dict" />
        """
        #expect(MDictReader.extractAttribute("Format", from: header) == "Html")
        #expect(MDictReader.extractAttribute("Title", from: header) == "Test Dict")
        #expect(MDictReader.extractAttribute("KeyCaseSensitive", from: header) == "No")
        #expect(MDictReader.extractAttribute("Missing", from: header) == nil)
    }

    @Test("Encrypted header value supports legacy strings")
    func testParseEncryptedValue() {
        #expect(MDictReader.parseEncryptedValue("0") == 0)
        #expect(MDictReader.parseEncryptedValue("No") == 0)
        #expect(MDictReader.parseEncryptedValue("2") == 2)
        #expect(MDictReader.parseEncryptedValue("Yes") == 1)
    }

    @Test("Resource text decoder uses preferred header encoding")
    func testDecodeResourceTextUsesPreferredEncoding() throws {
        let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        ))
        let data = try #require("发音样式".data(using: encoding))

        #expect(MDictDictionary.decodeResourceText(data, preferredEncoding: encoding) == "发音样式")
    }

    @Test("External MDX and MDD lookup flow")
    func testExternalMDictLookupFlow() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let mdxPath = environment["EASYDICT_MDICT_INTEGRATION_MDX"],
              let mddPath = environment["EASYDICT_MDICT_INTEGRATION_MDD"]
        else { return }

        let mdxURL = URL(fileURLWithPath: mdxPath)
        let mddURL = URL(fileURLWithPath: mddPath)
        let reader = try MDictReader(url: mdxURL)
        let words = ["hello", "apple", "good", "test", "dictionary"]
        let definitions = try words.compactMap { try reader.lookup($0) }

        #expect(!definitions.isEmpty)
        #expect(definitions.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        guard let resourceKey = definitions.compactMap(Self.firstResourceKey(in:)).first else {
            Issue.record("Expected at least one local resource reference")
            return
        }

        let dictionary = try MDictDictionary(mdxURL: mdxURL, mddURLs: [mddURL])
        let resource = try dictionary.lookupResource(resourceKey)
        #expect(resource?.isEmpty == false)
    }

    @Test("MDict lookup follows keyword link records")
    func testLookupFollowsKeywordLinkRecords() throws {
        let mdxURL = try Self.makeTemporaryMDX(records: [
            "book": "<div>book definition</div>",
            "books": "@@@LINK=book",
        ])
        defer { try? FileManager.default.removeItem(at: mdxURL) }

        let dictionary = try MDictDictionary(mdxURL: mdxURL)

        #expect(try dictionary.lookup("books") == "<div>book definition</div>")
    }

    @Test("MDict lookup resolves keyword link records among duplicate keys")
    func testLookupResolvesKeywordLinksAmongDuplicateKeys() throws {
        let mdxURL = try Self.makeTemporaryMDX(records: [
            ("book", "<div>book definition</div>"),
            ("books", "@@@LINK=book"),
            ("books", "<div>books variant</div>"),
        ])
        defer { try? FileManager.default.removeItem(at: mdxURL) }

        let dictionary = try MDictDictionary(mdxURL: mdxURL)

        #expect(
            try dictionary.lookup("books")
                == "<div>book definition</div>\n<div>books variant</div>"
        )
    }

    @Test("MDict keyword link targets do not use fuzzy fallback")
    func testKeywordLinkTargetsDoNotUseFuzzyFallback() throws {
        let mdxURL = try Self.makeTemporaryMDX(records: [
            "alias": "@@@LINK=boook",
            "book": "<div>book definition</div>",
        ])
        defer { try? FileManager.default.removeItem(at: mdxURL) }

        let dictionary = try MDictDictionary(mdxURL: mdxURL)

        #expect(try dictionary.lookup("alias") == "@@@LINK=boook")
    }

    @Test("MDict keyword link marker trims target word")
    func testLinkedKeywordTrimsTargetWord() {
        #expect(MDictDictionary.linkedKeyword(in: "\n@@@LINK=heads-up\n") == "heads-up")
        #expect(MDictDictionary.linkedKeyword(in: "@@@LINK=  book  ") == "book")
        #expect(MDictDictionary.linkedKeyword(in: "<div>book</div>") == nil)
    }

    // MARK: - Decompression

    @Test("Zlib decompression round-trip")
    func testZlibDecompression() throws {
        let original = Data("Hello, MDict decompression test!".utf8)
        let compressed = try MDictReader.zlibCompress(original)

        var block = Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(compressed)

        let decompressed = try MDictReader.decompressBlock(block, decompressedSize: original.count)
        #expect(decompressed == original)
    }

    @Test("Uncompressed block passthrough")
    func testUncompressedBlock() throws {
        let payload = Data("raw data".utf8)
        var block = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(payload)

        let result = try MDictReader.decompressBlock(block, decompressedSize: payload.count)
        #expect(result == payload)
    }

    @Test("LZO decompression supports literal stream")
    func testLZOLiteralDecompression() throws {
        let payload = Data("Hello, LZO!".utf8)
        var compressed = Data([UInt8(payload.count + 17)])
        compressed.append(payload)
        compressed.append(Data([0x11, 0x00, 0x00]))

        var block = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(compressed)

        let result = try MDictReader.decompressBlock(block, decompressedSize: payload.count)
        #expect(result == payload)
    }

    @Test("LZO decompression supports short back references")
    func testLZOBackReferenceDecompression() throws {
        let payload = Data("abcabcabc".utf8)
        let compressed = Data([
            0x14, 0x61, 0x62, 0x63,
            0x09, 0x00, 0x63,
            0x09, 0x00, 0x63,
            0x11, 0x00, 0x00,
        ])

        var block = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(compressed)

        let result = try MDictReader.decompressBlock(block, decompressedSize: payload.count)
        #expect(result == payload)
    }

    @Test("Unsupported compression type throws MDictError")
    func testUnsupportedCompression() {
        var block = Data([0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(Data("data".utf8))

        #expect(throws: MDictError.self) {
            try MDictReader.decompressBlock(block, decompressedSize: 4)
        }
    }

    @Test("Encrypted key block info keeps compression header")
    func testEncryptedKeyBlockInfoKeepsCompressionHeader() {
        var block = Data([0x02, 0x00, 0x00, 0x00, 0xE9, 0x04, 0x8C, 0xE8])
        block.append(Data([0xAA, 0xBB, 0xCC, 0xDD]))

        let decrypted = MDictReader.decryptKeyBlockInfo(block)
        #expect(decrypted.prefix(8) == block.prefix(8))
    }

    @Test("RIPEMD-128 matches standard test vectors")
    func testRIPEMD128Digest() {
        #expect(hex(MDictReader.ripemd128Digest(Data())) == "cdf26213a150dc3ecb610f18f6b38b46")
        #expect(hex(MDictReader.ripemd128Digest(Data("a".utf8))) == "86be7afa339d0fc7cfc785e72f578d33")
        #expect(hex(MDictReader.ripemd128Digest(Data("abc".utf8))) == "c14a12199c66e4ba84636b0f69144c77")
    }

    @Test("Search index finds prefix substring and fuzzy candidates")
    func testSearchIndexCandidates() {
        let entries = ["apple", "application", "pineapple", "banana"].enumerated().map {
            MDictKeyEntry(word: $0.element, recordOffset: UInt64($0.offset), globalIndex: $0.offset)
        }
        let index = MDictSearchIndex(entries: entries, caseSensitive: false)

        #expect(Array(index.candidates(for: "app", limit: 3).prefix(2)) == ["apple", "application"])
        #expect(index.candidates(for: "eap", limit: 3).first == "pineapple")
        #expect(index.candidates(for: "applf", limit: 3).contains("apple"))
    }

    @Test("Inflection candidates include common base forms")
    func testInflectionCandidates() {
        #expect(MDictInflection.candidates(for: "studies").contains("study"))
        #expect(MDictInflection.candidates(for: "running").contains("run"))
        #expect(MDictInflection.candidates(for: "larger").contains("large"))
    }

    @Test("Truncated MDX throws instead of crashing")
    func testTruncatedMDXThrows() throws {
        let header = """
        <Dictionary GeneratedByEngineVersion="2.0" Format="Html" Encoding="utf-8" />
        """
        let headerData = Data(header.utf16LittleEndianBytes)
        var data = Data([
            UInt8((headerData.count >> 24) & 0xFF),
            UInt8((headerData.count >> 16) & 0xFF),
            UInt8((headerData.count >> 8) & 0xFF),
            UInt8(headerData.count & 0xFF),
        ])
        data.append(headerData)
        data.append(Data([0x00, 0x00, 0x00, 0x00]))
        data.append(Data([0x00, 0x01]))

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mdx")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: MDictError.self) {
            try MDictReader(url: url)
        }
    }

    // MARK: - Binary reading

    @Test("ReadUInt32BE interprets big-endian bytes correctly")
    func testReadUInt32BE() {
        let data = Data([0x00, 0x01, 0x00, 0x00])
        #expect(MDictReader.readUInt32BE(data, at: 0) == 0x0001_0000)
    }

    @Test("ReadUInt64BE interprets big-endian bytes correctly")
    func testReadUInt64BE() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00])
        #expect(MDictReader.readUInt64BE(data, at: 0) == 0x0000_0000_0001_0000)
    }

    @Test("findNullTerminator locates single-byte null")
    func testFindNullTerminatorSingleByte() {
        let data = Data([0x41, 0x42, 0x00, 0x43])
        #expect(MDictReader.findNullTerminator(data, from: 0, terminatorSize: 1) == 2)
    }

    @Test("findNullTerminator locates double-byte null for UTF-16")
    func testFindNullTerminatorDoubleByte() {
        let data = Data([0x41, 0x00, 0x42, 0x00, 0x00, 0x00])
        #expect(MDictReader.findNullTerminator(data, from: 0, terminatorSize: 2) == 4)
    }

    // MARK: Private

    private static func firstResourceKey(in html: String) -> String? {
        let patterns = [
            #"(?i)(?:src|href|poster)\s*=\s*["']([^"']+\.(?:css|js|png|jpg|jpeg|gif|svg|webp|mp3|wav|ogg))["']"#,
            #"(?i)sound://([^"'\s)<>]+)"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(
                      in: html,
                      range: NSRange(html.startIndex..., in: html)
                  ),
                  let range = Range(match.range(at: 1), in: html)
            else { continue }
            let key = String(html[range])
            let lowercased = key.lowercased()
            guard !lowercased.hasPrefix("http://"),
                  !lowercased.hasPrefix("https://"),
                  !lowercased.hasPrefix("data:"),
                  !lowercased.hasPrefix("#")
            else { continue }
            return key
        }
        return nil
    }

    private static func makeTemporaryMDX(records: [String: String]) throws -> URL {
        let orderedRecords = records.map { (key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
        return try makeTemporaryMDX(orderedRecords: orderedRecords)
    }

    private static func makeTemporaryMDX(records: [(String, String)]) throws -> URL {
        let indexedRecords: [(offset: Int, key: String, value: String)] = records.enumerated()
            .map { record in
                (offset: record.offset, key: record.element.0, value: record.element.1)
            }
        let sortedRecords = indexedRecords.sorted { first, second in
            if first.key == second.key {
                return first.offset < second.offset
            }
            return first.key < second.key
        }
        let orderedRecords: [(key: String, value: String)] = sortedRecords.map { record in
            (key: record.key, value: record.value)
        }
        return try makeTemporaryMDX(orderedRecords: orderedRecords)
    }

    private static func makeTemporaryMDX(
        orderedRecords: [(key: String, value: String)]
    ) throws
        -> URL {
        let header = """
        <Dictionary GeneratedByEngineVersion="2.0" Format="Html" \
        KeyCaseSensitive="No" Encoding="utf-8" Title="Test Dict" />
        """
        let headerData = Data(header.utf16LittleEndianBytes)
        var data = Data()
        data.appendUInt32BE(UInt32(headerData.count))
        data.append(headerData)
        data.append(Data([0x00, 0x00, 0x00, 0x00]))

        var keyBlock = Data()
        var recordBlock = Data()
        for record in orderedRecords {
            keyBlock.appendUInt64BE(UInt64(recordBlock.count))
            keyBlock.append(Data(record.key.utf8))
            keyBlock.append(0)
            recordBlock.append(Data(record.value.utf8))
        }

        let keyBlockBytes = uncompressedBlock(keyBlock)
        var keyInfo = Data()
        keyInfo.appendUInt64BE(UInt64(orderedRecords.count))
        keyInfo.appendBoundary(orderedRecords[0].key)
        keyInfo.appendBoundary(orderedRecords[orderedRecords.count - 1].key)
        keyInfo.appendUInt64BE(UInt64(keyBlockBytes.count))
        keyInfo.appendUInt64BE(UInt64(keyBlock.count))
        let keyInfoBytes = uncompressedBlock(keyInfo)

        data.appendUInt64BE(1)
        data.appendUInt64BE(UInt64(orderedRecords.count))
        data.appendUInt64BE(UInt64(keyInfo.count))
        data.appendUInt64BE(UInt64(keyInfoBytes.count))
        data.appendUInt64BE(UInt64(keyBlockBytes.count))
        data.append(Data([0x00, 0x00, 0x00, 0x00]))
        data.append(keyInfoBytes)
        data.append(keyBlockBytes)

        let recordBlockBytes = uncompressedBlock(recordBlock)
        data.appendUInt64BE(1)
        data.appendUInt64BE(UInt64(orderedRecords.count))
        data.appendUInt64BE(16)
        data.appendUInt64BE(UInt64(recordBlockBytes.count))
        data.appendUInt64BE(UInt64(recordBlockBytes.count))
        data.appendUInt64BE(UInt64(recordBlock.count))
        data.append(recordBlockBytes)

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mdx")
        try data.write(to: url)
        return url
    }

    private static func uncompressedBlock(_ payload: Data) -> Data {
        var data = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        data.append(payload)
        return data
    }

    private func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

extension String {
    fileprivate var utf16LittleEndianBytes: [UInt8] {
        utf16.flatMap { unit in
            [UInt8(unit & 0xFF), UInt8(unit >> 8)]
        }
    }
}

extension Data {
    fileprivate mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    fileprivate mutating func appendUInt64BE(_ value: UInt64) {
        for shift in stride(from: 56, through: 0, by: -8) {
            append(UInt8((value >> UInt64(shift)) & 0xFF))
        }
    }

    fileprivate mutating func appendBoundary(_ key: String) {
        append(UInt8((key.utf8.count >> 8) & 0xFF))
        append(UInt8(key.utf8.count & 0xFF))
        append(Data(key.utf8))
        append(0)
    }
}
