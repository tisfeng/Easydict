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

/// Tests for the MDict binary format parser (header parsing, decompression, and key index).
@Suite("MDict Reader", .tags(.unit))
struct MDictReaderTests {
    // MARK: - Header parsing

    @Test("Extract attribute from XML-like header text")
    func testExtractAttribute() {
        let header = """
        <Dictionary GeneratedByEngineVersion="2.0" Format="Html" \
        KeyCaseSensitive="No" Encoding="utf-8" Title="Test Dict" />
        """
        #expect(MDictReader.extractAttributeForTesting("Format", from: header) == "Html")
        #expect(MDictReader.extractAttributeForTesting("Title", from: header) == "Test Dict")
        #expect(MDictReader.extractAttributeForTesting("KeyCaseSensitive", from: header) == "No")
        #expect(MDictReader.extractAttributeForTesting("Missing", from: header) == nil)
    }

    // MARK: - Decompression

    @Test("Zlib decompression round-trip")
    func testZlibDecompression() throws {
        let original = "Hello, MDict decompression test!".data(using: .utf8)!
        let compressed = try MDictReader.zlibCompressForTesting(original)

        // Wrap with the 8-byte MDict header (type 0x02000000 + 4-byte checksum placeholder)
        var block = Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(compressed)

        let decompressed = try MDictReader.decompressBlockForTesting(
            block, decompressedSize: original.count
        )
        #expect(decompressed == original)
    }

    @Test("Uncompressed block passthrough")
    func testUncompressedBlock() throws {
        let payload = "raw data".data(using: .utf8)!
        var block = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append(payload)

        let result = try MDictReader.decompressBlockForTesting(
            block, decompressedSize: payload.count
        )
        #expect(result == payload)
    }

    @Test("Unsupported compression throws")
    func testUnsupportedCompression() {
        var block = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        block.append("data".data(using: .utf8)!)

        #expect(throws: MDictError.self) {
            try MDictReader.decompressBlockForTesting(block, decompressedSize: 4)
        }
    }

    // MARK: - Binary reading utilities

    @Test("ReadUInt32BE reads big-endian uint32 correctly")
    func testReadUInt32BE() {
        let data = Data([0x00, 0x01, 0x00, 0x00])
        let value = MDictReader.readUInt32BEForTesting(data, at: 0)
        #expect(value == 0x0001_0000)
    }

    @Test("ReadUInt64BE reads big-endian uint64 correctly")
    func testReadUInt64BE() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00])
        let value = MDictReader.readUInt64BEForTesting(data, at: 0)
        #expect(value == 0x0000_0000_0001_0000)
    }

    @Test("findNullTerminator finds single-byte null correctly")
    func testFindNullTerminatorSingleByte() {
        let data = Data([0x41, 0x42, 0x00, 0x43])
        let pos = MDictReader.findNullTerminatorForTesting(data, from: 0, terminatorSize: 1)
        #expect(pos == 2)
    }

    @Test("findNullTerminator finds double-byte null correctly")
    func testFindNullTerminatorDoubleByte() {
        let data = Data([0x41, 0x00, 0x42, 0x00, 0x00, 0x00])
        let pos = MDictReader.findNullTerminatorForTesting(data, from: 0, terminatorSize: 2)
        #expect(pos == 4)
    }
}
