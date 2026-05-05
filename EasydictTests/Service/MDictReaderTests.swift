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

    @Test("Unsupported compression type throws MDictError")
    func testUnsupportedCompression() {
        var block = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
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
