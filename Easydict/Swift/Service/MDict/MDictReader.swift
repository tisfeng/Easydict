//
//  MDictReader.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - MDictError

/// Errors produced when parsing or querying MDict (MDX/MDD) files.
enum MDictError: LocalizedError {
    case invalidFormat(String)
    case unsupportedCompression(UInt32)
    case decompressionFailed
    case encodingError
    case encrypted

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .invalidFormat(detail):
            return "Invalid MDict format: \(detail)"
        case let .unsupportedCompression(type):
            return "Unsupported compression type \(type); only zlib (2) and none (0) are supported"
        case .decompressionFailed:
            return "Failed to decompress data block"
        case .encodingError:
            return "Failed to decode text with the specified encoding"
        case .encrypted:
            return "Encrypted MDict files are not supported"
        }
    }
}

let maxMDictDecompressedBlockSize = 256 * 1024 * 1024
let maxMDictCachedRecordBlockCount = 8
let maxMDictCachedRecordBlockBytes = 50 * 1024 * 1024

// MARK: - MDictHeader

/// Parsed metadata from the MDict file header XML.
struct MDictHeader {
    let version: Double
    let title: String
    let description: String
    let encoding: String.Encoding
    let format: String
    let keyCaseSensitive: Bool
    /// Raw value of the `Encrypted` attribute: 0 = none, 1 = key header (RegCode required), 2 = key index.
    let encrypted: Int

    var isHTML: Bool { format.lowercased().contains("html") }

    var nullTerminatorSize: Int {
        encoding == .utf16LittleEndian || encoding == .utf16BigEndian ? 2 : 1
    }
}

// MARK: - MDictKeyEntry

/// A single key-to-record mapping extracted from the key block section.
struct MDictKeyEntry {
    let word: String
    let recordOffset: UInt64
}

// MARK: - RecordBlockInfo

/// Compressed and decompressed sizes for one record block.
struct RecordBlockInfo {
    let compressedSize: UInt64
    let decompressedSize: UInt64
}

// MARK: - RecordBlockRange

/// Precomputed byte ranges for a decompressed record block.
///
/// Keeping cumulative compressed and decompressed offsets avoids rescanning all
/// preceding blocks for every lookup. The reader uses this table to binary
/// search the containing block and read the matching compressed bytes directly.
struct RecordBlockRange {
    let info: RecordBlockInfo
    let compressedStart: Int
    let decompressedStart: UInt64

    var decompressedEnd: UInt64 {
        decompressedStart + info.decompressedSize
    }
}

// MARK: - RecordSpan

/// Offset and length for a single dictionary record.
///
/// This value is cheap to hash, letting duplicate headword records be filtered
/// before reading and hashing large definition payloads.
struct RecordSpan: Hashable {
    let offset: UInt64
    let size: Int
}

// MARK: - MDictReader

/// Reads and parses MDict binary files (MDX for definitions, MDD for resources).
///
/// Supports format versions 1.x and 2.x with zlib or uncompressed data blocks.
/// Builds an in-memory key index on init and decompresses record blocks on demand.
final class MDictReader {
    // MARK: Lifecycle

    init(url: URL) throws {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        self.data = data

        var cursor = 0
        self.header = try Self.parseHeader(data, cursor: &cursor)

        if header.encrypted == 1 {
            throw MDictError.encrypted
        }

        self.keyEntries = try Self.parseKeyBlocks(
            data, cursor: &cursor, header: header
        )

        let (infos, blocksStart) = try Self.parseRecordBlockInfo(
            data, cursor: &cursor, header: header
        )
        self.recordBlockRanges = try Self.buildRecordBlockRanges(
            infos,
            blocksStart: blocksStart
        )

        self.keyIndex = Self.buildKeyIndex(keyEntries, caseSensitive: header.keyCaseSensitive)
    }

    // MARK: Internal

    let header: MDictHeader
    let keyEntries: [MDictKeyEntry]

    let data: Data
    let recordBlockRanges: [RecordBlockRange]
    let keyIndex: [String: [Int]]
    var decompressedBlockCache: [Int: Data] = [:]
    var decompressedBlockCacheOrder: [Int] = []
    var decompressedBlockCacheBytes = 0

    var totalDecompressedRecordSize: UInt64 {
        recordBlockRanges.last?.decompressedEnd ?? 0
    }

    static func buildRecordBlockRanges(
        _ infos: [RecordBlockInfo],
        blocksStart: Int
    ) throws
        -> [RecordBlockRange] {
        var compressedStart = blocksStart
        var decompressedStart: UInt64 = 0
        var ranges: [RecordBlockRange] = []
        ranges.reserveCapacity(infos.count)

        for info in infos {
            ranges.append(RecordBlockRange(
                info: info,
                compressedStart: compressedStart,
                decompressedStart: decompressedStart
            ))
            compressedStart += try checkedInt(
                info.compressedSize,
                context: "record block compressed size"
            )
            decompressedStart += info.decompressedSize
        }
        return ranges
    }

    /// Look up a text definition by word (MDX files).
    func lookup(_ word: String) throws -> String? {
        guard let data = try lookupData(for: word) else { return nil }
        return decodeTextRecord(data)
    }

    /// Look up all text definitions for a word (MDX files).
    func lookupAll(_ word: String) throws -> [String] {
        let records = try lookupAllData(for: word)
        return records.compactMap(decodeTextRecord)
    }

    /// Look up raw binary data by key (MDD files).
    func lookupData(for key: String) throws -> Data? {
        let normalizedKey = header.keyCaseSensitive ? key : key.lowercased()
        guard let index = keyIndex[normalizedKey]?.first else { return nil }

        return try lookupData(at: index)
    }

    /// Look up all raw binary records by key.
    func lookupAllData(for key: String) throws -> [Data] {
        let normalizedKey = header.keyCaseSensitive ? key : key.lowercased()
        guard let indexes = keyIndex[normalizedKey] else { return [] }

        var records: [Data] = []
        var seen = Set<RecordSpan>()
        for index in indexes {
            let span = try recordSpan(at: index)
            guard seen.insert(span).inserted else { continue }
            records.append(try readRecord(at: span.offset, size: span.size))
        }
        return records
    }

    func decodeTextRecord(_ data: Data) -> String? {
        String(data: data, encoding: header.encoding)?
            .replacingOccurrences(of: "\0", with: "")
    }

    func lookupData(at index: Int) throws -> Data {
        let span = try recordSpan(at: index)
        return try readRecord(at: span.offset, size: span.size)
    }

    func recordSpan(at index: Int) throws -> RecordSpan {
        guard keyEntries.indices.contains(index) else {
            throw MDictError.invalidFormat("Key index \(index) out of range")
        }

        let entry = keyEntries[index]
        let nextOffset: UInt64
        if index + 1 < keyEntries.count {
            nextOffset = keyEntries[index + 1].recordOffset
        } else {
            nextOffset = totalDecompressedRecordSize
        }
        guard nextOffset >= entry.recordOffset else {
            throw MDictError.invalidFormat("Record offsets are not sorted")
        }
        let recordSize = Int(nextOffset - entry.recordOffset)
        return RecordSpan(offset: entry.recordOffset, size: recordSize)
    }
}
