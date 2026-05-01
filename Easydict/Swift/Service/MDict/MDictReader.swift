//
//  MDictReader.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import zlib

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
        var seen = Set<Data>()
        for index in indexes {
            let record = try lookupData(at: index)
            guard seen.insert(record).inserted else { continue }
            records.append(record)
        }
        return records
    }

    // MARK: Private

    private let data: Data
    private let recordBlockInfos: [RecordBlockInfo]
    private let recordBlocksStart: Int
    private let keyIndex: [String: [Int]]

    private var totalDecompressedRecordSize: UInt64 {
        recordBlockInfos.reduce(0) { $0 + $1.decompressedSize }
    }

    private func decodeTextRecord(_ data: Data) -> String? {
        String(data: data, encoding: header.encoding)?
            .replacingOccurrences(of: "\0", with: "")
    }

    private func lookupData(at index: Int) throws -> Data {
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
        return try readRecord(at: entry.recordOffset, size: recordSize)
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
        let encryptedStr = extractAttribute("Encrypted", from: headerText) ?? "0"
        let encrypted = Int(encryptedStr) ?? 0

        let encoding: String.Encoding
        let normalizedEncoding = encodingStr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalizedEncoding {
        case "utf-16", "utf-16le":
            encoding = .utf16LittleEndian
        case "utf-16be":
            encoding = .utf16BigEndian
        case "gb2312", "gb18030", "gbk":
            encoding = .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            ))
        case "big5":
            encoding = .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.big5.rawValue)
            ))
        case "" where headerText.contains("<Library_Data"):
            encoding = .utf16LittleEndian
        default:
            encoding = .utf8
        }

        return MDictHeader(
            version: version,
            title: title,
            description: description,
            encoding: encoding,
            format: formatStr,
            keyCaseSensitive: caseSensitive.lowercased() == "yes",
            encrypted: encrypted
        )
    }

    static func extractAttribute(_ name: String, from text: String) -> String? {
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
    ) throws
        -> [MDictKeyEntry] {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt: (Data, Int) throws -> UInt64 = isV2
            ? { d, o in try checkedReadUInt64BE(d, at: o) }
            : { d, o in UInt64(try checkedReadUInt32BE(d, at: o)) }

        let numKeyBlocks = try readInt(data, cursor)
        cursor += intSize
        let numEntries = try readInt(data, cursor)
        cursor += intSize
        guard let numKeyBlocksInt = Int(exactly: numKeyBlocks),
              let numEntriesInt = Int(exactly: numEntries)
        else {
            throw MDictError.invalidFormat("Key block count exceeds supported size")
        }

        var keyBlockInfoDecompSize: UInt64 = 0
        if isV2 {
            keyBlockInfoDecompSize = try readInt(data, cursor)
            cursor += intSize
        }

        let keyBlockInfoSize = try readInt(data, cursor)
        cursor += intSize
        _ = try readInt(data, cursor)
        cursor += intSize

        if isV2 {
            try ensureAvailable(data, at: cursor, count: 4, context: "key block checksum")
            cursor += 4
        }

        let keyBlockInfoBytes: Data
        if isV2, keyBlockInfoSize > 0 {
            let keyBlockInfoSizeInt = try checkedInt(
                keyBlockInfoSize,
                context: "key block info size"
            )
            var compressed = try checkedSubdata(data, at: cursor, count: keyBlockInfoSizeInt)
            if header.encrypted & 2 != 0 {
                compressed = decryptKeyBlockInfo(compressed)
            }
            keyBlockInfoBytes = try decompressBlock(
                compressed,
                decompressedSize: try checkedInt(
                    keyBlockInfoDecompSize,
                    context: "key block info decompressed size"
                )
            )
        } else {
            keyBlockInfoBytes = try checkedSubdata(
                data,
                at: cursor,
                count: try checkedInt(keyBlockInfoSize, context: "key block info size")
            )
        }
        cursor += try checkedInt(keyBlockInfoSize, context: "key block info size")

        var blockSizes: [(compressed: Int, decompressed: Int)] = []
        var infoOffset = 0
        for _ in 0 ..< numKeyBlocksInt {
            try ensureAvailable(keyBlockInfoBytes, at: infoOffset, count: intSize, context: "key block entry count")
            infoOffset += intSize

            if isV2 {
                let wordSize = Int(try checkedReadUInt16BE(keyBlockInfoBytes, at: infoOffset))
                infoOffset += 2
                let firstKeySize = keyBlockTextSize(wordSize, header: header, isV2: isV2)
                try ensureAvailable(
                    keyBlockInfoBytes,
                    at: infoOffset,
                    count: firstKeySize,
                    context: "key block first key"
                )
                infoOffset += firstKeySize

                let lastSize = Int(try checkedReadUInt16BE(keyBlockInfoBytes, at: infoOffset))
                infoOffset += 2
                let lastKeySize = keyBlockTextSize(lastSize, header: header, isV2: isV2)
                try ensureAvailable(
                    keyBlockInfoBytes,
                    at: infoOffset,
                    count: lastKeySize,
                    context: "key block last key"
                )
                infoOffset += lastKeySize
            } else {
                try ensureAvailable(keyBlockInfoBytes, at: infoOffset, count: 1, context: "key block first key size")
                let wordSize = Int(keyBlockInfoBytes[infoOffset])
                infoOffset += 1
                let firstKeySize = keyBlockTextSize(wordSize, header: header, isV2: isV2)
                try ensureAvailable(
                    keyBlockInfoBytes,
                    at: infoOffset,
                    count: firstKeySize,
                    context: "key block first key"
                )
                infoOffset += firstKeySize

                try ensureAvailable(keyBlockInfoBytes, at: infoOffset, count: 1, context: "key block last key size")
                let lastSize = Int(keyBlockInfoBytes[infoOffset])
                infoOffset += 1
                let lastKeySize = keyBlockTextSize(lastSize, header: header, isV2: isV2)
                try ensureAvailable(
                    keyBlockInfoBytes,
                    at: infoOffset,
                    count: lastKeySize,
                    context: "key block last key"
                )
                infoOffset += lastKeySize
            }

            let compSize = try checkedInt(
                try readInt(keyBlockInfoBytes, infoOffset),
                context: "key block compressed size"
            )
            infoOffset += intSize
            let decompSize = try checkedInt(
                try readInt(keyBlockInfoBytes, infoOffset),
                context: "key block decompressed size"
            )
            infoOffset += intSize

            blockSizes.append((compSize, decompSize))
        }

        var entries: [MDictKeyEntry] = []
        entries.reserveCapacity(numEntriesInt)
        let offsetWidth = isV2 ? 8 : 4

        for blockSize in blockSizes {
            let blockData: Data
            if blockSize.compressed == blockSize.decompressed {
                blockData = try checkedSubdata(data, at: cursor, count: blockSize.compressed)
            } else {
                let compressed = try checkedSubdata(data, at: cursor, count: blockSize.compressed)
                blockData = try decompressBlock(compressed, decompressedSize: blockSize.decompressed)
            }
            cursor += blockSize.compressed

            var pos = 0
            while pos < blockData.count {
                try ensureAvailable(blockData, at: pos, count: offsetWidth, context: "key entry record offset")
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
                guard wordEnd < blockData.count else {
                    throw MDictError.invalidFormat("Key entry is missing a null terminator")
                }
                let wordBytes = blockData.subdata(in: pos ..< wordEnd)
                pos = wordEnd + header.nullTerminatorSize

                if let word = String(data: wordBytes, encoding: header.encoding) {
                    entries.append(MDictKeyEntry(word: word, recordOffset: recordOffset))
                }
            }
        }

        return entries
    }

    private static func keyBlockTextSize(
        _ codeUnitCount: Int,
        header: MDictHeader,
        isV2: Bool
    )
        -> Int {
        let terminatorUnits = isV2 ? 1 : 0
        let units = codeUnitCount + terminatorUnits
        if header.encoding == .utf16LittleEndian || header.encoding == .utf16BigEndian {
            return units * 2
        }
        return units
    }
}

// MARK: - Record Block Parsing

extension MDictReader {
    fileprivate static func parseRecordBlockInfo(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws
        -> ([RecordBlockInfo], Int) {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt: (Data, Int) throws -> UInt64 = isV2
            ? { d, o in try checkedReadUInt64BE(d, at: o) }
            : { d, o in UInt64(try checkedReadUInt32BE(d, at: o)) }

        let numRecordBlocks = try readInt(data, cursor)
        cursor += intSize
        // num_entries
        try ensureAvailable(data, at: cursor, count: intSize, context: "record entry count")
        cursor += intSize
        // record_block_info_size
        _ = try readInt(data, cursor)
        cursor += intSize
        // record_blocks_size
        try ensureAvailable(data, at: cursor, count: intSize, context: "record blocks size")
        cursor += intSize

        var infos: [RecordBlockInfo] = []
        guard let numRecordBlocksInt = Int(exactly: numRecordBlocks) else {
            throw MDictError.invalidFormat("Record block count exceeds supported size")
        }
        infos.reserveCapacity(numRecordBlocksInt)
        for _ in 0 ..< numRecordBlocksInt {
            let compSize = try readInt(data, cursor)
            cursor += intSize
            let decompSize = try readInt(data, cursor)
            cursor += intSize
            infos.append(RecordBlockInfo(compressedSize: compSize, decompressedSize: decompSize))
        }

        return (infos, cursor)
    }

    private func readRecord(at offset: UInt64, size: Int) throws -> Data {
        guard size > 0 else { return Data() }

        var cumulativeOffset: UInt64 = 0
        var blockDataStart = recordBlocksStart
        var remainingSize = size
        var readOffset = offset
        var record = Data()

        for info in recordBlockInfos {
            let blockEnd = cumulativeOffset + info.decompressedSize
            if readOffset >= cumulativeOffset, readOffset < blockEnd {
                let compressed = try Self.checkedSubdata(
                    data,
                    at: blockDataStart,
                    count: Self.checkedInt(info.compressedSize, context: "record block compressed size")
                )
                let decompressed = try Self.decompressBlock(
                    compressed,
                    decompressedSize: Self.checkedInt(
                        info.decompressedSize,
                        context: "record block decompressed size"
                    )
                )

                let localOffset = Int(readOffset - cumulativeOffset)
                guard localOffset <= decompressed.count else {
                    throw MDictError.invalidFormat("Record local offset \(localOffset) out of range")
                }
                let actualSize = min(remainingSize, decompressed.count - localOffset)
                if actualSize > 0 {
                    record.append(decompressed.subdata(in: localOffset ..< localOffset + actualSize))
                    remainingSize -= actualSize
                    readOffset += UInt64(actualSize)
                    if remainingSize == 0 { return record }
                }
            }
            cumulativeOffset = blockEnd
            blockDataStart += try Self.checkedInt(info.compressedSize, context: "record block compressed size")
        }

        if !record.isEmpty {
            throw MDictError.invalidFormat("Record at offset \(offset) exceeds record blocks")
        }
        throw MDictError.invalidFormat("Record offset \(offset) out of range")
    }
}

// MARK: - Binary Utilities

extension MDictReader {
    private static func ensureAvailable(
        _ data: Data,
        at offset: Int,
        count: Int,
        context: String
    ) throws {
        guard offset >= 0, count >= 0, offset <= data.count, count <= data.count - offset else {
            throw MDictError.invalidFormat("\(context) exceeds file bounds")
        }
    }

    private static func checkedSubdata(_ data: Data, at offset: Int, count: Int) throws -> Data {
        try ensureAvailable(data, at: offset, count: count, context: "Data range")
        return data.subdata(in: offset ..< offset + count)
    }

    private static func checkedInt(_ value: UInt64, context: String) throws -> Int {
        guard let result = Int(exactly: value) else {
            throw MDictError.invalidFormat("\(context) exceeds supported size")
        }
        return result
    }

    private static func checkedReadUInt16BE(_ data: Data, at offset: Int) throws -> UInt16 {
        try ensureAvailable(data, at: offset, count: 2, context: "UInt16")
        return readUInt16BE(data, at: offset)
    }

    private static func checkedReadUInt32BE(_ data: Data, at offset: Int) throws -> UInt32 {
        try ensureAvailable(data, at: offset, count: 4, context: "UInt32")
        return readUInt32BE(data, at: offset)
    }

    private static func checkedReadUInt64BE(_ data: Data, at offset: Int) throws -> UInt64 {
        try ensureAvailable(data, at: offset, count: 8, context: "UInt64")
        return readUInt64BE(data, at: offset)
    }

    static func readUInt16BE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }

    static func readUInt32BE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset]) << 24
            | UInt32(data[offset + 1]) << 16
            | UInt32(data[offset + 2]) << 8
            | UInt32(data[offset + 3])
    }

    static func readUInt64BE(_ data: Data, at offset: Int) -> UInt64 {
        UInt64(data[offset]) << 56
            | UInt64(data[offset + 1]) << 48
            | UInt64(data[offset + 2]) << 40
            | UInt64(data[offset + 3]) << 32
            | UInt64(data[offset + 4]) << 24
            | UInt64(data[offset + 5]) << 16
            | UInt64(data[offset + 6]) << 8
            | UInt64(data[offset + 7])
    }

    static func findNullTerminator(
        _ data: Data,
        from offset: Int,
        terminatorSize: Int
    )
        -> Int {
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

    static func decompressBlock(
        _ compressed: Data,
        decompressedSize: Int
    ) throws
        -> Data {
        guard compressed.count >= 8 else {
            throw MDictError.invalidFormat("Compressed block too small")
        }

        let compressionType = readUInt32BE(compressed, at: 0)
        let payload = compressed.subdata(in: 8 ..< compressed.count)

        switch compressionType {
        case 0x0000_0000:
            guard payload.count == decompressedSize else {
                throw MDictError.decompressionFailed
            }
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
    ) throws
        -> Data {
        guard decompressedSize >= 0 else { throw MDictError.decompressionFailed }
        var destination = Data(count: decompressedSize)
        var destinationSize = uLongf(decompressedSize)
        let status = source.withUnsafeBytes { srcPtr in
            destination.withUnsafeMutableBytes { dstPtr in
                uncompress(
                    dstPtr.baseAddress!.assumingMemoryBound(to: Bytef.self),
                    &destinationSize,
                    srcPtr.baseAddress!.assumingMemoryBound(to: Bytef.self),
                    uLong(source.count)
                )
            }
        }
        guard status == Z_OK, destinationSize == decompressedSize else {
            throw MDictError.decompressionFailed
        }
        return destination
    }

    /// Compress `source` with raw deflate. Used only in tests.
    static func zlibCompress(_ source: Data) throws -> Data {
        var outputSize = compressBound(uLong(source.count))
        var output = Data(count: Int(outputSize))
        let status = source.withUnsafeBytes { srcPtr in
            output.withUnsafeMutableBytes { dstPtr in
                compress2(
                    dstPtr.baseAddress!.assumingMemoryBound(to: Bytef.self),
                    &outputSize,
                    srcPtr.baseAddress!.assumingMemoryBound(to: Bytef.self),
                    uLong(source.count),
                    Z_DEFAULT_COMPRESSION
                )
            }
        }
        guard status == Z_OK else { throw MDictError.decompressionFailed }
        output.count = Int(outputSize)
        return output
    }

    /// Decrypt the key block info section for MDict files with `Encrypted="2"`.
    ///
    /// Uses a nibble-swap XOR cipher keyed on `ripemd128(adler32 || 0x95360000)`.
    /// The compression type and checksum header remain unencrypted.
    static func decryptKeyBlockInfo(_ data: Data) -> Data {
        guard data.count > 8 else { return data }
        let checksum = data.subdata(in: 4 ..< 8)
        let keyInput = checksum + Data([0x95, 0x36, 0x00, 0x00])
        let key = ripemd128(keyInput)

        var result = data
        var previous: UInt8 = 0x36
        for i in 8 ..< data.count {
            let keyIndex = (i - 8) % 16
            let offset = UInt8((i - 8) & 0xFF)
            let encrypted = data[i]
            result[i] = swapNibble(encrypted) ^ offset ^ key[keyIndex] ^ previous
            previous = encrypted
        }
        return result
    }

    static func ripemd128Digest(_ data: Data) -> [UInt8] {
        ripemd128(data)
    }

    private static func swapNibble(_ byte: UInt8) -> UInt8 {
        (byte >> 4) | (byte << 4)
    }
}

// MARK: - RIPEMD-128

/// Pure-Swift RIPEMD-128 used for `Encrypted="2"` key derivation.
///
/// Implements the reference specification from https://homes.esat.kuleuven.be/~cosicart/pdf/AB-9601/AB-9601.pdf
private func ripemd128(_ data: Data) -> [UInt8] {
    // Initial hash values
    var h0: UInt32 = 0x6745_2301
    var h1: UInt32 = 0xEFCD_AB89
    var h2: UInt32 = 0x98BA_DCFE
    var h3: UInt32 = 0x1032_5476

    // Padding
    var msg = [UInt8](data)
    let bitLength = UInt64(data.count) * 8
    msg.append(0x80)
    while msg.count % 64 != 56 { msg.append(0) }
    for i in 0 ..< 8 { msg.append(UInt8((bitLength >> (i * 8)) & 0xFF)) }

    // Process 512-bit (64-byte) blocks
    for blockStart in stride(from: 0, to: msg.count, by: 64) {
        var x = [UInt32](repeating: 0, count: 16)
        for i in 0 ..< 16 {
            let o = blockStart + i * 4
            x[i] = UInt32(msg[o]) | UInt32(msg[o + 1]) << 8
                | UInt32(msg[o + 2]) << 16 | UInt32(msg[o + 3]) << 24
        }

        var (a, b, c, d) = (h0, h1, h2, h3)
        var (aa, bb, cc, dd) = (h0, h1, h2, h3)

        let rol: (UInt32, UInt32) -> UInt32 = { v, s in (v << s) | (v >> (32 - s)) }
        let f: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in x ^ y ^ z }
        let g: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in (x & y) | (~x & z) }
        let h: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in (x | ~y) ^ z }
        let i: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in (x & z) | (y & ~z) }

        let rIdx = [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            7,
            4,
            13,
            1,
            10,
            6,
            15,
            3,
            12,
            0,
            9,
            5,
            2,
            14,
            11,
            8,
            3,
            10,
            14,
            4,
            9,
            15,
            8,
            1,
            2,
            7,
            0,
            6,
            13,
            11,
            5,
            12,
            1,
            9,
            11,
            10,
            0,
            8,
            12,
            4,
            13,
            3,
            7,
            15,
            14,
            5,
            6,
            2,
        ]
        let rIdxP = [
            5,
            14,
            7,
            0,
            9,
            2,
            11,
            4,
            13,
            6,
            15,
            8,
            1,
            10,
            3,
            12,
            6,
            11,
            3,
            7,
            0,
            13,
            5,
            10,
            14,
            15,
            8,
            12,
            4,
            9,
            1,
            2,
            15,
            5,
            1,
            3,
            7,
            14,
            6,
            9,
            11,
            8,
            12,
            2,
            10,
            0,
            4,
            13,
            8,
            6,
            4,
            1,
            3,
            11,
            15,
            0,
            5,
            12,
            2,
            13,
            9,
            7,
            10,
            14,
        ]
        let sLeft: [UInt32] = [
            11,
            14,
            15,
            12,
            5,
            8,
            7,
            9,
            11,
            13,
            14,
            15,
            6,
            7,
            9,
            8,
            7,
            6,
            8,
            13,
            11,
            9,
            7,
            15,
            7,
            12,
            15,
            9,
            11,
            7,
            13,
            12,
            11,
            13,
            6,
            7,
            14,
            9,
            13,
            15,
            14,
            8,
            13,
            6,
            5,
            12,
            7,
            5,
            11,
            12,
            14,
            15,
            14,
            15,
            9,
            8,
            9,
            14,
            5,
            6,
            8,
            6,
            5,
            12,
        ]
        let sRight: [UInt32] = [
            8,
            9,
            9,
            11,
            13,
            15,
            15,
            5,
            7,
            7,
            8,
            11,
            14,
            14,
            12,
            6,
            9,
            13,
            15,
            7,
            12,
            8,
            9,
            11,
            7,
            7,
            12,
            7,
            6,
            15,
            13,
            11,
            9,
            7,
            15,
            11,
            8,
            6,
            6,
            14,
            12,
            13,
            5,
            14,
            13,
            13,
            7,
            5,
            15,
            5,
            8,
            11,
            14,
            14,
            6,
            14,
            6,
            9,
            12,
            9,
            12,
            5,
            15,
            8,
        ]
        let kLeft: [UInt32] = [0x0000_0000, 0x5A82_7999, 0x6ED9_EBA1, 0x8F1B_BCDC]
        let kRight: [UInt32] = [0x50A2_8BE6, 0x5C4D_D124, 0x6D70_3EF3, 0x0000_0000]
        let fns = [f, g, h, i]
        let fnOrder = [0, 1, 2, 3]
        let fnOrderP = [3, 2, 1, 0]

        for round in 0 ..< 4 {
            let fn = fns[fnOrder[round]]
            let fnP = fns[fnOrderP[round]]
            let k = kLeft[round]
            let kP = kRight[round]
            for j in 0 ..< 16 {
                let idx = round * 16 + j
                let tmp = rol(a &+ fn(b, c, d) &+ x[rIdx[idx]] &+ k, sLeft[idx])
                a = d; d = c; c = b; b = tmp

                let tmpP = rol(aa &+ fnP(bb, cc, dd) &+ x[rIdxP[idx]] &+ kP, sRight[idx])
                aa = dd; dd = cc; cc = bb; bb = tmpP
            }
        }

        let t = h1 &+ c &+ dd
        h1 = h2 &+ d &+ aa
        h2 = h3 &+ a &+ bb
        h3 = h0 &+ b &+ cc
        h0 = t
    }

    var digest = [UInt8](repeating: 0, count: 16)
    for (i, val) in [h0, h1, h2, h3].enumerated() {
        digest[i * 4] = UInt8(val & 0xFF)
        digest[i * 4 + 1] = UInt8((val >> 8) & 0xFF)
        digest[i * 4 + 2] = UInt8((val >> 16) & 0xFF)
        digest[i * 4 + 3] = UInt8((val >> 24) & 0xFF)
    }
    return digest
}

// MARK: - Key Index

extension MDictReader {
    fileprivate static func buildKeyIndex(
        _ entries: [MDictKeyEntry],
        caseSensitive: Bool
    )
        -> [String: [Int]] {
        var index: [String: [Int]] = [:]
        index.reserveCapacity(entries.count)
        for (i, entry) in entries.enumerated() {
            let key = caseSensitive ? entry.word : entry.word.lowercased()
            index[key, default: []].append(i)
        }
        return index
    }
}
