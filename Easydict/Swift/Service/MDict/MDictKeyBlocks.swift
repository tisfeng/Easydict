//
//  MDictKeyBlocks.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/02.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - KeyBlockMetadata

/// Header values needed to read key block info and entries.
private struct KeyBlockMetadata {
    let isV2: Bool
    let blockCount: Int
    let entryCount: Int
    let infoSize: Int
    let infoDecompressedSize: Int
}

// MARK: - Key Block Parsing

extension MDictReader {
    static func parseKeyBlocks(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws
        -> [MDictKeyEntry] {
        let metadata = try readKeyBlockMetadata(data, cursor: &cursor, header: header)
        let infoBytes = try readKeyBlockInfoBytes(
            data,
            cursor: &cursor,
            metadata: metadata,
            header: header
        )
        let blockSizes = try parseKeyBlockSizes(
            infoBytes,
            blockCount: metadata.blockCount,
            header: header
        )

        return try parseKeyEntries(
            data,
            cursor: &cursor,
            blockSizes: blockSizes,
            entryCount: metadata.entryCount,
            header: header
        )
    }

    private static func readKeyBlockMetadata(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws
        -> KeyBlockMetadata {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt = integerReader(isV2: isV2)

        let numKeyBlocks = try readInt(data, cursor)
        cursor += intSize
        let numEntries = try readInt(data, cursor)
        cursor += intSize
        guard let blockCount = Int(exactly: numKeyBlocks),
              let entryCount = Int(exactly: numEntries)
        else {
            throw MDictError.invalidFormat("Key block count exceeds supported size")
        }

        let keyBlockInfoDecompressedSize = isV2 ? try readInt(data, cursor) : 0
        if isV2 { cursor += intSize }

        let keyBlockInfoSize = try readInt(data, cursor)
        cursor += intSize
        _ = try readInt(data, cursor)
        cursor += intSize

        let infoSize = try checkedInt(
            keyBlockInfoSize,
            context: "key block info size"
        )
        let infoDecompressedSize = try checkedInt(
            keyBlockInfoDecompressedSize,
            context: "key block info decompressed size"
        )

        if isV2 {
            try ensureAvailable(data, at: cursor, count: 4, context: "key block checksum")
            cursor += 4
        }

        return KeyBlockMetadata(
            isV2: isV2,
            blockCount: blockCount,
            entryCount: entryCount,
            infoSize: infoSize,
            infoDecompressedSize: infoDecompressedSize
        )
    }

    private static func readKeyBlockInfoBytes(
        _ data: Data,
        cursor: inout Int,
        metadata: KeyBlockMetadata,
        header: MDictHeader
    ) throws
        -> Data {
        let keyBlockInfoBytes: Data
        if metadata.isV2, metadata.infoSize > 0 {
            var compressed = try checkedSubdata(data, at: cursor, count: metadata.infoSize)
            if header.encrypted & 2 != 0 {
                compressed = decryptKeyBlockInfo(compressed)
            }
            keyBlockInfoBytes = try decompressBlock(
                compressed,
                decompressedSize: metadata.infoDecompressedSize
            )
        } else {
            keyBlockInfoBytes = try checkedSubdata(
                data,
                at: cursor,
                count: metadata.infoSize
            )
        }
        cursor += metadata.infoSize
        return keyBlockInfoBytes
    }

    private static func parseKeyBlockSizes(
        _ keyBlockInfoBytes: Data,
        blockCount: Int,
        header: MDictHeader
    ) throws
        -> [(compressed: Int, decompressed: Int)] {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt = integerReader(isV2: isV2)
        var blockSizes: [(compressed: Int, decompressed: Int)] = []
        var infoOffset = 0
        for _ in 0 ..< blockCount {
            try ensureAvailable(keyBlockInfoBytes, at: infoOffset, count: intSize, context: "key block entry count")
            infoOffset += intSize

            try skipKeyBlockBoundaryText(
                keyBlockInfoBytes,
                offset: &infoOffset,
                context: "key block first key",
                header: header
            )
            try skipKeyBlockBoundaryText(
                keyBlockInfoBytes,
                offset: &infoOffset,
                context: "key block last key",
                header: header
            )

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
        return blockSizes
    }

    private static func parseKeyEntries(
        _ data: Data,
        cursor: inout Int,
        blockSizes: [(compressed: Int, decompressed: Int)],
        entryCount: Int,
        header: MDictHeader
    ) throws
        -> [MDictKeyEntry] {
        let isV2 = header.version >= 2.0
        let offsetWidth = isV2 ? 8 : 4
        var entries: [MDictKeyEntry] = []
        entries.reserveCapacity(entryCount)

        for blockSize in blockSizes {
            let blockData = try readKeyBlockData(
                data,
                cursor: cursor,
                blockSize: blockSize
            )
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

    private static func readKeyBlockData(
        _ data: Data,
        cursor: Int,
        blockSize: (compressed: Int, decompressed: Int)
    ) throws
        -> Data {
        if blockSize.compressed == blockSize.decompressed {
            return try checkedSubdata(data, at: cursor, count: blockSize.compressed)
        }
        let compressed = try checkedSubdata(data, at: cursor, count: blockSize.compressed)
        return try decompressBlock(compressed, decompressedSize: blockSize.decompressed)
    }

    private static func skipKeyBlockBoundaryText(
        _ data: Data,
        offset: inout Int,
        context: String,
        header: MDictHeader
    ) throws {
        let isV2 = header.version >= 2.0
        let wordSize = try readKeyBlockTextUnitCount(data, offset: &offset, isV2: isV2)
        let textSize = keyBlockTextSize(wordSize, header: header, isV2: isV2)
        try ensureAvailable(data, at: offset, count: textSize, context: context)
        offset += textSize
    }

    private static func readKeyBlockTextUnitCount(
        _ data: Data,
        offset: inout Int,
        isV2: Bool
    ) throws
        -> Int {
        if isV2 {
            let wordSize = Int(try checkedReadUInt16BE(data, at: offset))
            offset += 2
            return wordSize
        }

        try ensureAvailable(data, at: offset, count: 1, context: "key block key size")
        let wordSize = Int(data[offset])
        offset += 1
        return wordSize
    }

    private static func integerReader(isV2: Bool) -> (Data, Int) throws -> UInt64 {
        isV2
            ? { dataBytes, offset in try checkedReadUInt64BE(dataBytes, at: offset) }
            : { dataBytes, offset in UInt64(try checkedReadUInt32BE(dataBytes, at: offset)) }
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
