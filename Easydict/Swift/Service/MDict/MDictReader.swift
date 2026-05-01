//
//  MDictReader.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Compression
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
        case .invalidFormat(let detail):
            return "Invalid MDict format: \(detail)"
        case .unsupportedCompression(let type):
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

// MARK: - MDictHeader

/// Parsed metadata from the MDict file header XML.
struct MDictHeader {
    let version: Double
    let title: String
    let description: String
    let encoding: String.Encoding
    let format: String
    let keyCaseSensitive: Bool

    var isHTML: Bool { format.lowercased().contains("html") }

    var nullTerminatorSize: Int {
        encoding == .utf16LittleEndian ? 2 : 1
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

// MARK: - MDictReader

/// Reads and parses MDict binary files (MDX for definitions, MDD for resources).
///
/// Supports format versions 1.x and 2.x with zlib or uncompressed data blocks.
/// Builds an in-memory key index on init and decompresses record blocks on demand.
final class MDictReader {
    // MARK: Lifecycle

    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self.data = data

        var cursor = 0
        self.header = try Self.parseHeader(data, cursor: &cursor)

        if header.version >= 2.0 {
            let encrypted = Self.readAttribute("Encrypted", from: data)
            if encrypted == "1" || encrypted == "2" {
                throw MDictError.encrypted
            }
        }

        self.keyEntries = try Self.parseKeyBlocks(
            data, cursor: &cursor, header: header
        )

        let (infos, blocksStart) = try Self.parseRecordBlockInfo(
            data, cursor: &cursor, header: header
        )
        self.recordBlockInfos = infos
        self.recordBlocksStart = blocksStart

        self.keyIndex = Self.buildKeyIndex(keyEntries, caseSensitive: header.keyCaseSensitive)
    }

    // MARK: Internal

    let header: MDictHeader
    let keyEntries: [MDictKeyEntry]

    /// Look up a text definition by word (MDX files).
    func lookup(_ word: String) throws -> String? {
        guard let data = try lookupData(for: word) else { return nil }
        return String(data: data, encoding: header.encoding)
    }

    /// Look up raw binary data by key (MDD files).
    func lookupData(for key: String) throws -> Data? {
        let normalizedKey = header.keyCaseSensitive ? key : key.lowercased()
        guard let index = keyIndex[normalizedKey] else { return nil }

        let entry = keyEntries[index]
        let nextOffset: UInt64
        if index + 1 < keyEntries.count {
            nextOffset = keyEntries[index + 1].recordOffset
        } else {
            nextOffset = totalDecompressedRecordSize
        }
        let recordSize = Int(nextOffset - entry.recordOffset)
        return try readRecord(at: entry.recordOffset, size: recordSize)
    }

    // MARK: Private

    private let data: Data
    private let recordBlockInfos: [RecordBlockInfo]
    private let recordBlocksStart: Int
    private let keyIndex: [String: Int]

    private var totalDecompressedRecordSize: UInt64 {
        recordBlockInfos.reduce(0) { $0 + $1.decompressedSize }
    }
}

// MARK: - Header Parsing

extension MDictReader {
    fileprivate static func parseHeader(_ data: Data, cursor: inout Int) throws -> MDictHeader {
        guard data.count >= 4 else {
            throw MDictError.invalidFormat("File too small")
        }
        let headerSize = Int(readUInt32BE(data, at: cursor))
        cursor += 4

        guard cursor + headerSize + 4 <= data.count else {
            throw MDictError.invalidFormat("Header size exceeds file")
        }
        let headerBytes = data.subdata(in: cursor ..< cursor + headerSize)
        cursor += headerSize
        cursor += 4

        guard let headerText = String(data: headerBytes, encoding: .utf16LittleEndian) else {
            throw MDictError.encodingError
        }

        let version = Double(extractAttribute("GeneratedByEngineVersion", from: headerText) ?? "2.0") ?? 2.0
        let title = extractAttribute("Title", from: headerText) ?? ""
        let description = extractAttribute("Description", from: headerText) ?? ""
        let formatStr = extractAttribute("Format", from: headerText) ?? "Html"
        let caseSensitive = extractAttribute("KeyCaseSensitive", from: headerText) ?? "No"
        let encodingStr = extractAttribute("Encoding", from: headerText) ?? "utf-8"

        let encoding: String.Encoding
        switch encodingStr.lowercased() {
        case "utf-16", "utf-16le":
            encoding = .utf16LittleEndian
        case "utf-16be":
            encoding = .utf16BigEndian
        case "gbk", "gb2312", "gb18030":
            encoding = .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            ))
        case "big5":
            encoding = .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.big5.rawValue)
            ))
        default:
            encoding = .utf8
        }

        return MDictHeader(
            version: version,
            title: title,
            description: description,
            encoding: encoding,
            format: formatStr,
            keyCaseSensitive: caseSensitive.lowercased() == "yes"
        )
    }

    private static func extractAttribute(_ name: String, from text: String) -> String? {
        let pattern = "\(name)=\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: text,
                  range: NSRange(text.startIndex..., in: text)
              ),
              let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[range])
    }

    fileprivate static func readAttribute(_ name: String, from data: Data) -> String? {
        guard data.count >= 8 else { return nil }
        let headerSize = Int(readUInt32BE(data, at: 0))
        guard headerSize + 4 <= data.count else { return nil }
        let headerBytes = data.subdata(in: 4 ..< 4 + headerSize)
        guard let text = String(data: headerBytes, encoding: .utf16LittleEndian) else { return nil }
        return extractAttribute(name, from: text)
    }
}

// MARK: - Key Block Parsing

extension MDictReader {
    fileprivate static func parseKeyBlocks(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws -> [MDictKeyEntry] {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt: (Data, Int) -> UInt64 = isV2
            ? { d, o in readUInt64BE(d, at: o) }
            : { d, o in UInt64(readUInt32BE(d, at: o)) }

        let numKeyBlocks = readInt(data, cursor)
        cursor += intSize
        let numEntries = readInt(data, cursor)
        cursor += intSize

        var keyBlockInfoDecompSize: UInt64 = 0
        if isV2 {
            keyBlockInfoDecompSize = readInt(data, cursor)
            cursor += intSize
        }

        let keyBlockInfoSize = readInt(data, cursor)
        cursor += intSize
        let keyBlocksSize = readInt(data, cursor)
        cursor += intSize

        if isV2 {
            cursor += 4
        }

        let keyBlockInfoBytes: Data
        if isV2, keyBlockInfoSize > 0 {
            let compressed = data.subdata(
                in: cursor ..< cursor + Int(keyBlockInfoSize)
            )
            keyBlockInfoBytes = try decompressBlock(
                compressed,
                decompressedSize: Int(keyBlockInfoDecompSize)
            )
        } else {
            keyBlockInfoBytes = data.subdata(
                in: cursor ..< cursor + Int(keyBlockInfoSize)
            )
        }
        cursor += Int(keyBlockInfoSize)

        var blockSizes: [(compressed: Int, decompressed: Int)] = []
        var infoOffset = 0
        for _ in 0 ..< numKeyBlocks {
            infoOffset += intSize

            if isV2 {
                let wordSize = Int(readUInt16BE(keyBlockInfoBytes, at: infoOffset))
                infoOffset += 2
                infoOffset += wordSize + header.nullTerminatorSize

                let lastSize = Int(readUInt16BE(keyBlockInfoBytes, at: infoOffset))
                infoOffset += 2
                infoOffset += lastSize + header.nullTerminatorSize
            } else {
                let wordSize = Int(keyBlockInfoBytes[infoOffset])
                infoOffset += 1
                infoOffset += wordSize + header.nullTerminatorSize

                let lastSize = Int(keyBlockInfoBytes[infoOffset])
                infoOffset += 1
                infoOffset += lastSize + header.nullTerminatorSize
            }

            let compSize = Int(readInt(keyBlockInfoBytes, infoOffset))
            infoOffset += intSize
            let decompSize = Int(readInt(keyBlockInfoBytes, infoOffset))
            infoOffset += intSize

            blockSizes.append((compSize, decompSize))
        }

        var entries: [MDictKeyEntry] = []
        entries.reserveCapacity(Int(numEntries))
        let offsetWidth = isV2 ? 8 : 4

        for blockSize in blockSizes {
            let blockData: Data
            if blockSize.compressed == blockSize.decompressed {
                blockData = data.subdata(in: cursor ..< cursor + blockSize.compressed)
            } else {
                let compressed = data.subdata(in: cursor ..< cursor + blockSize.compressed)
                blockData = try decompressBlock(compressed, decompressedSize: blockSize.decompressed)
            }
            cursor += blockSize.compressed

            var pos = 0
            while pos < blockData.count {
                let recordOffset: UInt64
                if isV2 {
                    recordOffset = readUInt64BE(blockData, at: pos)
                } else {
                    recordOffset = UInt64(readUInt32BE(blockData, at: pos))
                }
                pos += offsetWidth

                let wordEnd = findNullTerminator(
                    blockData, from: pos, terminatorSize: header.nullTerminatorSize
                )
                let wordBytes = blockData.subdata(in: pos ..< wordEnd)
                pos = wordEnd + header.nullTerminatorSize

                if let word = String(data: wordBytes, encoding: header.encoding) {
                    entries.append(MDictKeyEntry(word: word, recordOffset: recordOffset))
                }
            }
        }

        return entries
    }
}

// MARK: - Record Block Parsing

extension MDictReader {
    fileprivate static func parseRecordBlockInfo(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws -> ([RecordBlockInfo], Int) {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt: (Data, Int) -> UInt64 = isV2
            ? { d, o in readUInt64BE(d, at: o) }
            : { d, o in UInt64(readUInt32BE(d, at: o)) }

        let numRecordBlocks = readInt(data, cursor)
        cursor += intSize
        // num_entries
        cursor += intSize
        // record_block_info_size
        let recordBlockInfoSize = readInt(data, cursor)
        cursor += intSize
        // record_blocks_size
        cursor += intSize

        var infos: [RecordBlockInfo] = []
        infos.reserveCapacity(Int(numRecordBlocks))
        for _ in 0 ..< numRecordBlocks {
            let compSize = readInt(data, cursor)
            cursor += intSize
            let decompSize = readInt(data, cursor)
            cursor += intSize
            infos.append(RecordBlockInfo(compressedSize: compSize, decompressedSize: decompSize))
        }

        return (infos, cursor)
    }

    private func readRecord(at offset: UInt64, size: Int) throws -> Data {
        var cumulativeOffset: UInt64 = 0
        var blockDataStart = recordBlocksStart

        for info in recordBlockInfos {
            let blockEnd = cumulativeOffset + info.decompressedSize
            if offset >= cumulativeOffset, offset < blockEnd {
                let compressed = data.subdata(
                    in: blockDataStart ..< blockDataStart + Int(info.compressedSize)
                )
                let decompressed = try Self.decompressBlock(
                    compressed, decompressedSize: Int(info.decompressedSize)
                )

                let localOffset = Int(offset - cumulativeOffset)
                let actualSize = min(size, decompressed.count - localOffset)
                guard actualSize > 0 else { return Data() }
                return decompressed.subdata(in: localOffset ..< localOffset + actualSize)
            }
            cumulativeOffset = blockEnd
            blockDataStart += Int(info.compressedSize)
        }

        throw MDictError.invalidFormat("Record offset \(offset) out of range")
    }
}

// MARK: - Binary Utilities

extension MDictReader {
    fileprivate static func readUInt16BE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }

    fileprivate static func readUInt32BE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset]) << 24
            | UInt32(data[offset + 1]) << 16
            | UInt32(data[offset + 2]) << 8
            | UInt32(data[offset + 3])
    }

    fileprivate static func readUInt64BE(_ data: Data, at offset: Int) -> UInt64 {
        UInt64(data[offset]) << 56
            | UInt64(data[offset + 1]) << 48
            | UInt64(data[offset + 2]) << 40
            | UInt64(data[offset + 3]) << 32
            | UInt64(data[offset + 4]) << 24
            | UInt64(data[offset + 5]) << 16
            | UInt64(data[offset + 6]) << 8
            | UInt64(data[offset + 7])
    }

    fileprivate static func findNullTerminator(
        _ data: Data,
        from offset: Int,
        terminatorSize: Int
    ) -> Int {
        var pos = offset
        if terminatorSize == 2 {
            while pos + 1 < data.count {
                if data[pos] == 0, data[pos + 1] == 0 { return pos }
                pos += 2
            }
        } else {
            while pos < data.count {
                if data[pos] == 0 { return pos }
                pos += 1
            }
        }
        return data.count
    }

    fileprivate static func decompressBlock(
        _ compressed: Data,
        decompressedSize: Int
    ) throws -> Data {
        guard compressed.count >= 8 else {
            throw MDictError.invalidFormat("Compressed block too small")
        }

        let compressionType = readUInt32BE(compressed, at: 0)
        let payload = compressed.subdata(in: 8 ..< compressed.count)

        switch compressionType {
        case 0x0000_0000:
            return payload
        case 0x0200_0000:
            return try zlibDecompress(payload, decompressedSize: decompressedSize)
        default:
            throw MDictError.unsupportedCompression(compressionType)
        }
    }

    private static func zlibDecompress(
        _ source: Data,
        decompressedSize: Int
    ) throws -> Data {
        var destination = Data(count: decompressedSize)
        let result = source.withUnsafeBytes { srcPtr in
            destination.withUnsafeMutableBytes { dstPtr in
                compression_decode_buffer(
                    dstPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    decompressedSize,
                    srcPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    source.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard result > 0 else { throw MDictError.decompressionFailed }
        destination.count = result
        return destination
    }
}

// MARK: - Key Index

extension MDictReader {
    fileprivate static func buildKeyIndex(
        _ entries: [MDictKeyEntry],
        caseSensitive: Bool
    ) -> [String: Int] {
        var index: [String: Int] = [:]
        index.reserveCapacity(entries.count)
        for (i, entry) in entries.enumerated() {
            let key = caseSensitive ? entry.word : entry.word.lowercased()
            if index[key] == nil {
                index[key] = i
            }
        }
        return index
    }
}
