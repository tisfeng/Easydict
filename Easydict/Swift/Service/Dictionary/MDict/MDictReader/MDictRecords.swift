//
//  MDictRecords.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/02.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - Record Block Parsing

extension MDictReader {
    static func parseRecordBlockInfo(
        _ data: Data,
        cursor: inout Int,
        header: MDictHeader
    ) throws
        -> ([RecordBlockInfo], Int) {
        let isV2 = header.version >= 2.0
        let intSize = isV2 ? 8 : 4
        let readInt: (Data, Int) throws -> UInt64 = isV2
            ? { dataBytes, offset in try checkedReadUInt64BE(dataBytes, at: offset) }
            : { dataBytes, offset in UInt64(try checkedReadUInt32BE(dataBytes, at: offset)) }

        let numRecordBlocks = try readInt(data, cursor)
        cursor += intSize
        // num_entries
        try ensureAvailable(data, at: cursor, count: intSize, context: "record entry count")
        cursor += intSize
        // These aggregate sizes are advisory; each block range is bounds-checked
        // when read, so we only advance past them here.
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

    func readRecord(at offset: UInt64, size: Int) throws -> Data {
        guard size > 0 else { return Data() }

        var remainingSize = size
        var readOffset = offset
        var record = Data()

        while remainingSize > 0,
              let blockIndex = recordBlockIndex(containing: readOffset) {
            let range = recordBlockRanges[blockIndex]
            let decompressed = try decompressedRecordBlock(at: blockIndex)
            let localOffset = Int(readOffset - range.decompressedStart)
            guard localOffset <= decompressed.count else {
                throw MDictError.invalidFormat("Record local offset \(localOffset) out of range")
            }
            let actualSize = min(remainingSize, decompressed.count - localOffset)
            guard actualSize > 0 else { break }

            record.append(decompressed.subdata(in: localOffset ..< localOffset + actualSize))
            remainingSize -= actualSize
            readOffset += UInt64(actualSize)
            if readOffset == range.decompressedEnd, remainingSize > 0 {
                continue
            }
        }

        if remainingSize == 0 {
            return record
        }
        if !record.isEmpty {
            throw MDictError.invalidFormat("Record at offset \(offset) exceeds record blocks")
        }
        throw MDictError.invalidFormat("Record offset \(offset) out of range")
    }

    private func recordBlockIndex(containing offset: UInt64) -> Int? {
        var lower = 0
        var upper = recordBlockRanges.count

        while lower < upper {
            let mid = (lower + upper) / 2
            let range = recordBlockRanges[mid]
            if offset < range.decompressedStart {
                upper = mid
            } else if offset >= range.decompressedEnd {
                lower = mid + 1
            } else {
                return mid
            }
        }
        return nil
    }

    private func decompressedRecordBlock(at index: Int) throws -> Data {
        if let cached = decompressedBlockCache[index] {
            markRecordBlockCacheHit(index)
            return cached
        }

        let range = recordBlockRanges[index]
        let compressed = try Self.checkedSubdata(
            data,
            at: range.compressedStart,
            count: Self.checkedInt(
                range.info.compressedSize,
                context: "record block compressed size"
            )
        )
        let decompressed = try Self.decompressBlock(
            compressed,
            decompressedSize: Self.checkedInt(
                range.info.decompressedSize,
                context: "record block decompressed size"
            )
        )
        cacheDecompressedRecordBlock(decompressed, at: index)
        return decompressed
    }

    private func markRecordBlockCacheHit(_ index: Int) {
        decompressedBlockCacheOrder.removeAll { $0 == index }
        decompressedBlockCacheOrder.append(index)
    }

    private func cacheDecompressedRecordBlock(_ block: Data, at index: Int) {
        if let oldBlock = decompressedBlockCache[index] {
            decompressedBlockCacheBytes -= oldBlock.count
        }
        decompressedBlockCache[index] = block
        decompressedBlockCacheBytes += block.count
        markRecordBlockCacheHit(index)

        while decompressedBlockCacheOrder.count > maxMDictCachedRecordBlockCount
            || decompressedBlockCacheBytes > maxMDictCachedRecordBlockBytes,
            let evicted = decompressedBlockCacheOrder.first {
            decompressedBlockCacheOrder.removeFirst()
            if let evictedBlock = decompressedBlockCache.removeValue(forKey: evicted) {
                decompressedBlockCacheBytes -= evictedBlock.count
            }
        }
    }
}
