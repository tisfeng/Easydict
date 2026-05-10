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
        case 0x0100_0000:
            return try lzoDecompress(payload, decompressedSize: decompressedSize)
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

    private static func lzoDecompress(
        _ source: Data,
        decompressedSize: Int
    ) throws
        -> Data {
        guard decompressedSize >= 0, !source.isEmpty else {
            throw MDictError.decompressionFailed
        }

        let input = [UInt8](source)
        var output = [UInt8](repeating: 0, count: decompressedSize)
        var inputOffset = 0
        var outputOffset = 0
        var state = 0
        var instruction = try readLZOByte(input, offset: &inputOffset)

        if instruction >= 22 {
            try copyLZOLiterals(
                input,
                inputOffset: &inputOffset,
                output: &output,
                outputOffset: &outputOffset,
                count: Int(instruction) - 17
            )
            state = 4
        } else if instruction >= 18 {
            let literalCount = Int(instruction) - 17
            try copyLZOLiterals(
                input,
                inputOffset: &inputOffset,
                output: &output,
                outputOffset: &outputOffset,
                count: literalCount
            )
            state = literalCount
        }

        while true {
            if inputOffset > 1 || state > 0 {
                instruction = try readLZOByte(input, offset: &inputOffset)
            }

            let match: (distance: Int, length: Int, nextState: Int)?
            if instruction >= 64 {
                let tail = try readLZOByte(input, offset: &inputOffset)
                let distance = (Int(tail) << 3) + ((Int(instruction) >> 2) & 0x7) + 1
                match = (distance, (Int(instruction) >> 5) + 1, Int(instruction) & 0x03)
            } else if instruction >= 32 {
                var length = Int(instruction & 0x1F) + 2
                if length == 2 {
                    length += try readLZOExtendedLength(input, offset: &inputOffset, base: 31)
                }
                let distanceState = try readLZOUInt16LE(input, offset: &inputOffset)
                match = (Int(distanceState >> 2) + 1, length, Int(distanceState & 0x03))
            } else if instruction >= 16 {
                var length = Int(instruction & 0x07) + 2
                if length == 2 {
                    length += try readLZOExtendedLength(input, offset: &inputOffset, base: 7)
                }
                let distanceState = try readLZOUInt16LE(input, offset: &inputOffset)
                let baseDistance = ((Int(instruction) & 0x08) << 11)
                    + Int(distanceState >> 2)
                if baseDistance == 0 {
                    guard length == 3, outputOffset == decompressedSize else {
                        throw MDictError.decompressionFailed
                    }
                    return Data(output)
                }
                match = (baseDistance + 0x4000, length, Int(distanceState & 0x03))
            } else if state == 0 {
                var literalCount = Int(instruction) + 3
                if literalCount == 3 {
                    literalCount += try readLZOExtendedLength(
                        input,
                        offset: &inputOffset,
                        base: 15
                    )
                }
                try copyLZOLiterals(
                    input,
                    inputOffset: &inputOffset,
                    output: &output,
                    outputOffset: &outputOffset,
                    count: literalCount
                )
                guard inputOffset < input.count else {
                    throw MDictError.decompressionFailed
                }
                state = 4
                continue
            } else {
                let tail = try readLZOByte(input, offset: &inputOffset)
                let distance: Int
                let length: Int
                if state == 4 {
                    distance = 0x0800 + 1 + (Int(instruction) >> 2) + (Int(tail) << 2)
                    length = 3
                } else {
                    distance = (Int(instruction) >> 2) + (Int(tail) << 2) + 1
                    length = 2
                }
                match = (distance, length, Int(instruction) & 0x03)
            }

            guard let match else { throw MDictError.decompressionFailed }
            try copyLZOBackReference(
                output: &output,
                outputOffset: outputOffset,
                distance: match.distance,
                length: match.length
            )
            outputOffset += match.length

            if match.nextState > 0 {
                try copyLZOLiterals(
                    input,
                    inputOffset: &inputOffset,
                    output: &output,
                    outputOffset: &outputOffset,
                    count: match.nextState
                )
            }
            state = match.nextState
        }
    }

    private static func readLZOByte(_ input: [UInt8], offset: inout Int) throws -> UInt8 {
        guard offset < input.count else { throw MDictError.decompressionFailed }
        let byte = input[offset]
        offset += 1
        return byte
    }

    private static func readLZOUInt16LE(_ input: [UInt8], offset: inout Int) throws -> UInt16 {
        guard offset + 1 < input.count else { throw MDictError.decompressionFailed }
        let value = UInt16(input[offset]) | (UInt16(input[offset + 1]) << 8)
        offset += 2
        return value
    }

    private static func readLZOExtendedLength(
        _ input: [UInt8],
        offset: inout Int,
        base: Int
    ) throws
        -> Int {
        var zeroCount = 0
        while offset < input.count, input[offset] == 0 {
            zeroCount += 1
            offset += 1
        }
        let tail = try readLZOByte(input, offset: &offset)
        return zeroCount * 255 + base + Int(tail)
    }

    private static func copyLZOLiterals(
        _ input: [UInt8],
        inputOffset: inout Int,
        output: inout [UInt8],
        outputOffset: inout Int,
        count: Int
    ) throws {
        guard count >= 0,
              inputOffset + count <= input.count,
              outputOffset + count <= output.count
        else {
            throw MDictError.decompressionFailed
        }
        guard count > 0 else { return }

        output[outputOffset ..< outputOffset + count] =
            input[inputOffset ..< inputOffset + count]
        inputOffset += count
        outputOffset += count
    }

    private static func copyLZOBackReference(
        output: inout [UInt8],
        outputOffset: Int,
        distance: Int,
        length: Int
    ) throws {
        let matchOffset = outputOffset - distance
        guard distance > 0,
              length >= 0,
              matchOffset >= 0,
              outputOffset + length <= output.count
        else {
            throw MDictError.decompressionFailed
        }

        for index in 0 ..< length {
            output[outputOffset + index] = output[matchOffset + index]
        }
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
