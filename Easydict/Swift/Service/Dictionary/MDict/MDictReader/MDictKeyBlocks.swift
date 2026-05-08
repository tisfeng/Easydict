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

// MARK: - KeyBlockInfo

/// One row from key block info before it becomes an absolute file range.
private struct KeyBlockInfo {
    let entryCount: Int
    let firstKey: String
    let lastKey: String
    let compressedSize: Int
    let decompressedSize: Int
}

// MARK: - Key Block Parsing

extension MDictReader {
    static func parseKeyBlockRanges(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws
        -> ([MDictKeyBlockRange], Int) {
        let metadata = try readKeyBlockMetadata(data, cursor: &cursor, header: header)
        let infoBytes = try readKeyBlockInfoBytes(
            data,
            cursor: &cursor,
            metadata: metadata,
            header: header
        )
        let blockInfos = try parseKeyBlockInfos(
            infoBytes,
            blockCount: metadata.blockCount,
            header: header
        )

        let keyBlocksStart = cursor
        var compressedStart = keyBlocksStart
        var entryStartIndex = 0
        var ranges: [MDictKeyBlockRange] = []
        ranges.reserveCapacity(metadata.blockCount)

        for info in blockInfos {
            ranges.append(MDictKeyBlockRange(
                firstKey: info.firstKey,
                lastKey: info.lastKey,
                compressedStart: compressedStart,
                compressedSize: info.compressedSize,
                decompressedSize: info.decompressedSize,
                entryStartIndex: entryStartIndex,
                entryCount: info.entryCount
            ))
            compressedStart += info.compressedSize
            entryStartIndex += info.entryCount
        }

        guard entryStartIndex == metadata.entryCount else {
            throw MDictError.invalidFormat("Key block entry count mismatch")
        }

        cursor = compressedStart
        return (ranges, compressedStart)
    }

    func matchingEntries(for key: String) throws -> [MDictKeyEntry] {
        let normalized = normalizedKey(key)
        let blockIndexes = matchingKeyBlockIndexes(for: normalized)

        var matches: [MDictKeyEntry] = []
        for blockIndex in blockIndexes {
            let entries = try keyEntries(in: blockIndex)
            matches.append(contentsOf: matchingEntries(in: entries, for: normalized))
        }
        if !matches.isEmpty { return matches }

        let scannedIndexes = scannedKeyBlockIndexes(for: normalized)
            .filter { !blockIndexes.contains($0) }
        for blockIndex in scannedIndexes {
            let entries = try keyEntries(in: blockIndex)
            matches.append(contentsOf: matchingEntries(in: entries, for: normalized))
            if !matches.isEmpty { break }
        }
        return matches
    }

    func allKeyEntries() throws -> [MDictKeyEntry] {
        var entries: [MDictKeyEntry] = []
        entries.reserveCapacity(entryCount)
        for blockIndex in keyBlockRanges.indices {
            entries.append(contentsOf: try keyEntries(in: blockIndex))
        }
        return entries
    }

    func nextRecordOffset(after entry: MDictKeyEntry) throws -> UInt64 {
        guard entry.globalIndex + 1 < entryCount else {
            return totalDecompressedRecordSize
        }
        let nextIndex = entry.globalIndex + 1
        guard let nextBlockIndex = keyBlockIndex(containingEntry: nextIndex) else {
            throw MDictError.invalidFormat("Next key index \(nextIndex) out of range")
        }
        let nextBlock = try keyEntries(in: nextBlockIndex)
        let localIndex = nextIndex - keyBlockRanges[nextBlockIndex].entryStartIndex
        guard nextBlock.indices.contains(localIndex) else {
            throw MDictError.invalidFormat("Next key entry \(nextIndex) out of range")
        }
        return nextBlock[localIndex].recordOffset
    }

    private func keyEntries(in blockIndex: Int) throws -> [MDictKeyEntry] {
        if let cached = keyBlockCache[blockIndex] {
            markKeyBlockCacheHit(blockIndex)
            return cached
        }

        guard keyBlockRanges.indices.contains(blockIndex) else {
            throw MDictError.invalidFormat("Key block index \(blockIndex) out of range")
        }
        let range = keyBlockRanges[blockIndex]
        let blockData = try Self.readKeyBlockData(
            data,
            cursor: range.compressedStart,
            compressedSize: range.compressedSize,
            decompressedSize: range.decompressedSize
        )
        let entries = try Self.parseKeyEntries(
            blockData,
            entryStartIndex: range.entryStartIndex,
            expectedCount: range.entryCount,
            header: header
        )
        cacheKeyEntries(entries, at: blockIndex)
        return entries
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

    private static func parseKeyBlockInfos(
        _ keyBlockInfoBytes: Data,
        blockCount: Int,
        header: MDictHeader
    ) throws
        -> [KeyBlockInfo] {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt = integerReader(isV2: isV2)
        var blockInfos: [KeyBlockInfo] = []
        var infoOffset = 0
        for _ in 0 ..< blockCount {
            try ensureAvailable(keyBlockInfoBytes, at: infoOffset, count: intSize, context: "key block entry count")
            let entryCount = try checkedInt(
                try readInt(keyBlockInfoBytes, infoOffset),
                context: "key block entry count"
            )
            infoOffset += intSize

            let firstKey = try readKeyBlockBoundaryText(
                keyBlockInfoBytes,
                offset: &infoOffset,
                context: "key block first key",
                header: header
            )
            let lastKey = try readKeyBlockBoundaryText(
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

            blockInfos.append(KeyBlockInfo(
                entryCount: entryCount,
                firstKey: firstKey,
                lastKey: lastKey,
                compressedSize: compSize,
                decompressedSize: decompSize
            ))
        }
        return blockInfos
    }

    private static func parseKeyEntries(
        _ blockData: Data,
        entryStartIndex: Int,
        expectedCount: Int,
        header: MDictHeader
    ) throws
        -> [MDictKeyEntry] {
        let isV2 = header.version >= 2.0
        let offsetWidth = isV2 ? 8 : 4
        var entries: [MDictKeyEntry] = []
        entries.reserveCapacity(expectedCount)

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
                entries.append(MDictKeyEntry(
                    word: word,
                    recordOffset: recordOffset,
                    globalIndex: entryStartIndex + entries.count
                ))
            }
        }

        guard entries.count == expectedCount else {
            throw MDictError.invalidFormat("Key block parsed entry count mismatch")
        }
        return entries
    }

    private static func readKeyBlockData(
        _ data: Data,
        cursor: Int,
        compressedSize: Int,
        decompressedSize: Int
    ) throws
        -> Data {
        let compressed = try checkedSubdata(data, at: cursor, count: compressedSize)
        return try decompressBlock(compressed, decompressedSize: decompressedSize)
    }

    private static func readKeyBlockBoundaryText(
        _ data: Data,
        offset: inout Int,
        context: String,
        header: MDictHeader
    ) throws
        -> String {
        let isV2 = header.version >= 2.0
        let wordSize = try readKeyBlockTextUnitCount(data, offset: &offset, isV2: isV2)
        let textSize = keyBlockTextSize(wordSize, header: header, isV2: isV2)
        try ensureAvailable(data, at: offset, count: textSize, context: context)
        let textEnd = offset + textSize - (isV2 ? header.nullTerminatorSize : 0)
        let textBytes = data.subdata(in: offset ..< textEnd)
        offset += textSize
        guard let text = String(data: textBytes, encoding: header.encoding) else {
            throw MDictError.encodingError
        }
        return text
    }

    private func markKeyBlockCacheHit(_ index: Int) {
        keyBlockCacheOrder.removeAll { $0 == index }
        keyBlockCacheOrder.append(index)
    }

    private func cacheKeyEntries(_ entries: [MDictKeyEntry], at index: Int) {
        keyBlockCache[index] = entries
        markKeyBlockCacheHit(index)

        while keyBlockCacheOrder.count > maxMDictCachedKeyBlockCount,
              let evicted = keyBlockCacheOrder.first {
            keyBlockCacheOrder.removeFirst()
            keyBlockCache.removeValue(forKey: evicted)
        }
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
