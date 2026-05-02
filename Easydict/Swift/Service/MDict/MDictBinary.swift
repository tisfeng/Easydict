//
//  MDictBinary.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/02.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import zlib

// MARK: - Binary Utilities

extension MDictReader {
    static func ensureAvailable(
        _ data: Data,
        at offset: Int,
        count: Int,
        context: String
    ) throws {
        guard offset >= 0, count >= 0, offset <= data.count, count <= data.count - offset else {
            throw MDictError.invalidFormat("\(context) exceeds file bounds")
        }
    }

    static func checkedSubdata(_ data: Data, at offset: Int, count: Int) throws -> Data {
        try ensureAvailable(data, at: offset, count: count, context: "Data range")
        return data.subdata(in: offset ..< offset + count)
    }

    static func checkedInt(_ value: UInt64, context: String) throws -> Int {
        guard let result = Int(exactly: value) else {
            throw MDictError.invalidFormat("\(context) exceeds supported size")
        }
        return result
    }

    static func checkedReadUInt16BE(_ data: Data, at offset: Int) throws -> UInt16 {
        try ensureAvailable(data, at: offset, count: 2, context: "UInt16")
        return readUInt16BE(data, at: offset)
    }

    static func checkedReadUInt32BE(_ data: Data, at offset: Int) throws -> UInt32 {
        try ensureAvailable(data, at: offset, count: 4, context: "UInt32")
        return readUInt32BE(data, at: offset)
    }

    static func checkedReadUInt64BE(_ data: Data, at offset: Int) throws -> UInt64 {
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
            // MDict key text starts at an aligned UTF-16 boundary after the
            // fixed-width record offset, so stepping by code unit is safe.
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
        guard decompressedSize <= maxMDictDecompressedBlockSize else {
            throw MDictError.invalidFormat("Decompressed block size exceeds safety limit")
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

    #if DEBUG
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
    #endif

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
