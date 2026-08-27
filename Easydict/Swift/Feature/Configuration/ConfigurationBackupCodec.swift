//
//  ConfigurationBackupCodec.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import CommonCrypto
import CryptoKit
import Foundation
import Security

// MARK: - ConfigurationBackupCodec

/// Encodes and authenticates the fixed Easydict backup v1 binary format.
enum ConfigurationBackupCodec {
    // MARK: Internal

    static let maximumFileSize = 10 * 1024 * 1024
    static let iterationCount: UInt32 = 600_000
    static let saltLength = 32
    static let nonceLength = 12
    static let tagLength = 16

    static func encrypt(
        _ payload: ConfigurationBackupPayload,
        password: String,
        salt suppliedSalt: Data? = nil,
        nonce suppliedNonce: Data? = nil
    ) throws
        -> Data {
        let salt = try suppliedSalt ?? randomData(count: saltLength)
        let nonceData = try suppliedNonce ?? randomData(count: nonceLength)
        guard salt.count == saltLength, nonceData.count == nonceLength else {
            throw ConfigurationBackupError.invalidFormat
        }

        let plaintext = try encodePayload(payload)
        let key = try deriveKey(password: password, salt: salt, iterations: iterationCount)
        let nonce = try AES.GCM.Nonce(data: nonceData)

        var header = Data()
        header.append(magic)
        header.appendBigEndian(formatVersion)
        header.appendBigEndian(iterationCount)
        header.append(salt)
        header.append(nonceData)
        header.appendBigEndian(UInt64(plaintext.count))

        let sealed = try AES.GCM.seal(
            plaintext,
            using: key,
            nonce: nonce,
            authenticating: header
        )
        guard sealed.ciphertext.count == plaintext.count else {
            throw ConfigurationBackupError.invalidFormat
        }
        var result = header
        result.append(sealed.ciphertext)
        result.append(sealed.tag)
        guard result.count <= maximumFileSize else {
            throw ConfigurationBackupError.fileTooLarge
        }
        return result
    }

    static func decrypt(_ data: Data, password: String) throws -> ConfigurationBackupPayload {
        let envelope = try parseEnvelope(data)
        let key = try deriveKey(
            password: password,
            salt: envelope.salt,
            iterations: envelope.iterations
        )
        do {
            let nonce = try AES.GCM.Nonce(data: envelope.nonce)
            let sealed = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: envelope.ciphertext,
                tag: envelope.tag
            )
            let plaintext = try AES.GCM.open(
                sealed,
                using: key,
                authenticating: envelope.header
            )
            return try decodePayload(plaintext)
        } catch let error as ConfigurationBackupError {
            throw error
        } catch {
            throw ConfigurationBackupError.authenticationFailed
        }
    }

    // MARK: Private

    private struct Envelope {
        let iterations: UInt32
        let salt: Data
        let nonce: Data
        let header: Data
        let ciphertext: Data
        let tag: Data
    }

    private static let magic = Data("EASYBK01".utf8)
    private static let formatVersion: UInt16 = 1
    private static let fixedHeaderLength = 8 + 2 + 4 + saltLength + nonceLength + 8

    private static let payloadKeys = Set([
        "schemaVersion", "bundleIdentifier", "applicationVersion", "applicationBuild",
        "createdAt", "items",
    ])
    private static let itemKeys = Set(["descriptor", "valueKind", "value"])
    private static let descriptorKeys = Set(["name", "qualifiers"])

    private static func parseEnvelope(_ data: Data) throws -> Envelope {
        guard data.count <= maximumFileSize else { throw ConfigurationBackupError.fileTooLarge }
        guard data.count >= fixedHeaderLength + tagLength else {
            throw ConfigurationBackupError.invalidFormat
        }

        var cursor = 0
        guard data.read(count: magic.count, cursor: &cursor) == magic else {
            throw ConfigurationBackupError.invalidFormat
        }
        let version: UInt16 = try data.readBigEndian(cursor: &cursor)
        guard version == formatVersion else { throw ConfigurationBackupError.unsupportedVersion }
        let iterations: UInt32 = try data.readBigEndian(cursor: &cursor)
        guard iterations == iterationCount else {
            throw ConfigurationBackupError.unsupportedKDFParameters
        }
        let salt = data.read(count: saltLength, cursor: &cursor)
        let nonce = data.read(count: nonceLength, cursor: &cursor)
        let ciphertextLength: UInt64 = try data.readBigEndian(cursor: &cursor)
        guard ciphertextLength <= UInt64(maximumFileSize),
              let length = Int(exactly: ciphertextLength),
              cursor + length + tagLength == data.count
        else {
            throw ConfigurationBackupError.invalidFormat
        }
        let header = data.prefix(cursor)
        let ciphertext = data.read(count: length, cursor: &cursor)
        let tag = data.read(count: tagLength, cursor: &cursor)
        guard salt.count == saltLength, nonce.count == nonceLength,
              ciphertext.count == length, tag.count == tagLength, cursor == data.count
        else {
            throw ConfigurationBackupError.invalidFormat
        }
        return Envelope(
            iterations: iterations,
            salt: salt,
            nonce: nonce,
            header: Data(header),
            ciphertext: ciphertext,
            tag: tag
        )
    }

    private static func deriveKey(
        password: String,
        salt: Data,
        iterations: UInt32
    ) throws
        -> SymmetricKey {
        var passwordBytes = Array(password.utf8)
        var derivedBytes = [UInt8](repeating: 0, count: 32)
        let passwordLength = passwordBytes.count
        let derivedLength = derivedBytes.count
        defer {
            _ = passwordBytes.withUnsafeMutableBytes {
                $0.initializeMemory(as: UInt8.self, repeating: 0)
            }
            _ = derivedBytes.withUnsafeMutableBytes {
                $0.initializeMemory(as: UInt8.self, repeating: 0)
            }
        }

        let status: Int32 = passwordBytes.withUnsafeBytes { passwordBuffer in
            salt.withUnsafeBytes { saltBuffer in
                derivedBytes.withUnsafeMutableBytes { derivedBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.bindMemory(to: Int8.self).baseAddress,
                        passwordLength,
                        saltBuffer.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        iterations,
                        derivedBuffer.bindMemory(to: UInt8.self).baseAddress,
                        derivedLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw ConfigurationBackupError.invalidFormat }
        return SymmetricKey(data: derivedBytes)
    }

    private static func randomData(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw ConfigurationBackupError.invalidFormat
        }
        return Data(bytes)
    }

    private static func encodePayload(_ payload: ConfigurationBackupPayload) throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            return try encoder.encode(payload)
        } catch {
            throw ConfigurationBackupError.invalidPayload
        }
    }

    private static func decodePayload(_ data: Data) throws -> ConfigurationBackupPayload {
        try validatePayloadShape(data)
        do {
            return try PropertyListDecoder().decode(ConfigurationBackupPayload.self, from: data)
        } catch {
            throw ConfigurationBackupError.invalidPayload
        }
    }

    private static func validatePayloadShape(_ data: Data) throws {
        guard let payload = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dictionary = payload as? [String: Any],
              Set(dictionary.keys) == payloadKeys,
              let items = dictionary["items"] as? [[String: Any]]
        else { throw ConfigurationBackupError.invalidPayload }

        for item in items {
            guard Set(item.keys) == itemKeys,
                  let descriptor = item["descriptor"] as? [String: Any],
                  Set(descriptor.keys) == descriptorKeys
            else { throw ConfigurationBackupError.invalidPayload }
        }
    }
}

// MARK: - Data + Backup Binary

extension Data {
    fileprivate mutating func appendBigEndian<T: FixedWidthInteger>(_ value: T) {
        var value = value.bigEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }

    fileprivate func read(count: Int, cursor: inout Int) -> Data {
        guard count >= 0, cursor >= 0, cursor + count <= self.count else { return Data() }
        defer { cursor += count }
        return subdata(in: cursor ..< cursor + count)
    }

    fileprivate func readBigEndian<T: FixedWidthInteger>(cursor: inout Int) throws -> T {
        let bytes = read(count: MemoryLayout<T>.size, cursor: &cursor)
        guard bytes.count == MemoryLayout<T>.size else {
            throw ConfigurationBackupError.invalidFormat
        }
        return bytes.reduce(T.zero) { ($0 << 8) | T($1) }
    }
}
