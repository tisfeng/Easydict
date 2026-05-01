//
//  MDictReaderTests.swift
//  EasydictTests
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Compression
import Foundation
import Testing

@testable import Easydict

// MARK: - MDictReaderTests

/// Tests for the MDict binary format parser utilities (decompression, binary reading, key index).
@Suite("MDict Reader", .tags(.unit))
struct MDictReaderTests {
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
        let original = "Hello, MDict decompression test!".data(using: .utf8)!
        let compressed = try MDictReader.zlibCompress(original)

        var block = Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(compressed)

        let decompressed = try MDictReader.decompressBlock(block, decompressedSize: original.count)
        #expect(decompressed == original)
    }

    @Test("Uncompressed block passthrough")
    func testUncompressedBlock() throws {
        let payload = "raw data".data(using: .utf8)!
        var block = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(payload)

        let result = try MDictReader.decompressBlock(block, decompressedSize: payload.count)
        #expect(result == payload)
    }

    @Test("Unsupported compression type throws MDictError")
    func testUnsupportedCompression() {
        var block = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append("data".data(using: .utf8)!)

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
}
