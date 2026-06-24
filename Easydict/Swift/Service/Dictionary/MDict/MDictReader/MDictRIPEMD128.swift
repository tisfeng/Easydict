//
//  MDictRIPEMD128.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/02.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - RIPEMD-128

// swiftlint:disable identifier_name

/// Pure-Swift RIPEMD-128 used for `Encrypted="2"` key derivation.
///
/// Implements the reference specification from https://homes.esat.kuleuven.be/~cosicart/pdf/AB-9601/AB-9601.pdf
func ripemd128(_ data: Data) -> [UInt8] {
    var h0: UInt32 = 0x6745_2301
    var h1: UInt32 = 0xEFCD_AB89
    var h2: UInt32 = 0x98BA_DCFE
    var h3: UInt32 = 0x1032_5476

    let msg = ripemd128PaddedMessage(data)
    for blockStart in stride(from: 0, to: msg.count, by: 64) {
        let x = ripemd128MessageWords(from: msg, blockStart: blockStart)
        (h0, h1, h2, h3) = ripemd128Compress(x, state: (h0, h1, h2, h3))
    }

    return ripemd128DigestBytes([h0, h1, h2, h3])
}

private func ripemd128PaddedMessage(_ data: Data) -> [UInt8] {
    var msg = [UInt8](data)
    let bitLength = UInt64(data.count) * 8
    msg.append(0x80)
    while msg.count % 64 != 56 { msg.append(0) }
    for i in 0 ..< 8 { msg.append(UInt8((bitLength >> (i * 8)) & 0xFF)) }
    return msg
}

private func ripemd128MessageWords(from msg: [UInt8], blockStart: Int) -> [UInt32] {
    var x = [UInt32](repeating: 0, count: 16)
    for i in 0 ..< 16 {
        let o = blockStart + i * 4
        x[i] = UInt32(msg[o]) | UInt32(msg[o + 1]) << 8
            | UInt32(msg[o + 2]) << 16 | UInt32(msg[o + 3]) << 24
    }
    return x
}

private func ripemd128Compress(
    _ x: [UInt32],
    state: (UInt32, UInt32, UInt32, UInt32)
)
    -> (UInt32, UInt32, UInt32, UInt32) {
    var (a, b, c, d) = state
    var (aa, bb, cc, dd) = state

    let rol: (UInt32, UInt32) -> UInt32 = { v, s in (v << s) | (v >> (32 - s)) }
    let f: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in x ^ y ^ z }
    let g: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in (x & y) | (~x & z) }
    let h: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in (x | ~y) ^ z }
    let i: (UInt32, UInt32, UInt32) -> UInt32 = { x, y, z in (x & z) | (y & ~z) }

    let rIdx = [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
        7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8,
        3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12,
        1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2,
    ]
    let rIdxP = [
        5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12,
        6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
        15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13,
        8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
    ]
    let sLeft: [UInt32] = [
        11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8,
        7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
        11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5,
        11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
    ]
    let sRight: [UInt32] = [
        8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
        9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
        9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
        15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
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

    let h0 = state.0
    let h1 = state.1
    let h2 = state.2
    let h3 = state.3
    return (
        h1 &+ c &+ dd,
        h2 &+ d &+ aa,
        h3 &+ a &+ bb,
        h0 &+ b &+ cc
    )
}

private func ripemd128DigestBytes(_ values: [UInt32]) -> [UInt8] {
    var digest = [UInt8](repeating: 0, count: 16)
    for (i, val) in values.enumerated() {
        digest[i * 4] = UInt8(val & 0xFF)
        digest[i * 4 + 1] = UInt8((val >> 8) & 0xFF)
        digest[i * 4 + 2] = UInt8((val >> 16) & 0xFF)
        digest[i * 4 + 3] = UInt8((val >> 24) & 0xFF)
    }
    return digest
}

// swiftlint:enable identifier_name
