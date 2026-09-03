//
//  ConfigurationBackupCodecTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import CryptoKit
import Foundation
import Testing

@testable import Easydict

/// Verifies authenticated configuration backup encoding without writing files or using real credentials.
@Suite("Configuration Backup Codec", .tags(.unit))
struct ConfigurationBackupCodecTests {
    // MARK: Internal

    @Test("Round trips the encrypted binary envelope without plaintext leakage")
    func roundTripsEncryptedEnvelope() throws {
        let credentialCanary = "FAKE_CREDENTIAL_CANARY_MUST_NOT_APPEAR"
        let rawKeyCanary = "RAW_USER_DEFAULTS_KEY_CANARY_MUST_NOT_APPEAR"
        let descriptorCanary = "SEMANTIC_DESCRIPTOR_CANARY_MUST_NOT_APPEAR"
        let payload = makePayload(
            credentialCanary: credentialCanary,
            descriptorCanary: descriptorCanary
        )
        let encrypted = try ConfigurationBackupCodec.encrypt(
            payload,
            password: password,
            salt: fixedSalt,
            nonce: fixedNonce
        )
        let repeated = try ConfigurationBackupCodec.encrypt(
            payload,
            password: password,
            salt: fixedSalt,
            nonce: fixedNonce
        )

        #expect(encrypted == repeated)
        #expect(encrypted.starts(with: Data("EASYBK01".utf8)))
        #expect(encrypted.subdata(in: 8 ..< 10) == Data([0, 1]))
        #expect(encrypted.subdata(in: 10 ..< 14) == Data([0, 9, 39, 192]))
        #expect(encrypted.subdata(in: 14 ..< 46) == fixedSalt)
        #expect(encrypted.subdata(in: 46 ..< 58) == fixedNonce)
        #expect(encrypted.count <= ConfigurationBackupCodec.maximumFileSize)
        #expect(encrypted.range(of: Data(credentialCanary.utf8)) == nil)
        #expect(encrypted.range(of: Data(rawKeyCanary.utf8)) == nil)
        #expect(encrypted.range(of: Data(descriptorCanary.utf8)) == nil)

        let decrypted = try ConfigurationBackupCodec.decrypt(encrypted, password: password)
        assertEqual(decrypted, payload)
    }

    @Test("Uses fresh salt and nonce for each backup")
    func usesFreshRandomness() throws {
        let payload = makePayload()

        let first = try ConfigurationBackupCodec.encrypt(payload, password: password)
        let second = try ConfigurationBackupCodec.encrypt(payload, password: password)

        #expect(first != second)
        assertEqual(try ConfigurationBackupCodec.decrypt(first, password: password), payload)
        assertEqual(try ConfigurationBackupCodec.decrypt(second, password: password), payload)
    }

    @Test("Matches the fixed v1 envelope known-answer digest")
    func matchesFixedEnvelopeKnownAnswer() throws {
        let encrypted = try fixedEncryptedBackup()
        let digest = SHA256.hash(data: encrypted)
            .map { String(format: "%02x", $0) }
            .joined()

        #expect(encrypted.count == 498)
        #expect(digest == "86f016cc97a51ed5efa2989d584a29feec82c282458aa94afd29b480802f6958")
    }

    @Test("Rejects a wrong password as an authentication failure")
    func rejectsWrongPassword() throws {
        let encrypted = try fixedEncryptedBackup()

        #expect(throws: ConfigurationBackupError.authenticationFailed) {
            try ConfigurationBackupCodec.decrypt(encrypted, password: "different-password")
        }
    }

    @Test("Authenticates salt, nonce, ciphertext, and tag")
    func authenticatesEverySealedEnvelopeRegion() throws {
        let encrypted = try fixedEncryptedBackup()
        let offsets = [14, 46, 66, encrypted.count - 1]

        for offset in offsets {
            var tampered = encrypted
            tampered[offset] ^= 0x01

            #expect(throws: ConfigurationBackupError.authenticationFailed) {
                try ConfigurationBackupCodec.decrypt(tampered, password: password)
            }
        }
    }

    @Test("Rejects unsupported envelope version and KDF parameters before decryption")
    func rejectsUnsupportedEnvelopeMetadata() throws {
        let encrypted = try fixedEncryptedBackup()

        var unsupportedVersion = encrypted
        unsupportedVersion[8] = 0
        unsupportedVersion[9] = 2
        #expect(throws: ConfigurationBackupError.unsupportedVersion) {
            try ConfigurationBackupCodec.decrypt(unsupportedVersion, password: password)
        }

        var unsupportedIterations = encrypted
        unsupportedIterations[13] ^= 0x01
        #expect(throws: ConfigurationBackupError.unsupportedKDFParameters) {
            try ConfigurationBackupCodec.decrypt(unsupportedIterations, password: password)
        }
    }

    @Test("Rejects malformed, truncated, and oversized envelopes")
    func rejectsMalformedEnvelopeSizes() throws {
        let encrypted = try fixedEncryptedBackup()

        #expect(throws: ConfigurationBackupError.invalidFormat) {
            try ConfigurationBackupCodec.decrypt(Data(), password: password)
        }
        #expect(throws: ConfigurationBackupError.invalidFormat) {
            try ConfigurationBackupCodec.decrypt(Data(encrypted.dropLast()), password: password)
        }

        var invalidMagic = encrypted
        invalidMagic[0] ^= 0x01
        #expect(throws: ConfigurationBackupError.invalidFormat) {
            try ConfigurationBackupCodec.decrypt(invalidMagic, password: password)
        }

        var invalidLength = encrypted
        invalidLength[65] ^= 0x01
        #expect(throws: ConfigurationBackupError.invalidFormat) {
            try ConfigurationBackupCodec.decrypt(invalidLength, password: password)
        }

        let oversized = Data(
            repeating: 0,
            count: ConfigurationBackupCodec.maximumFileSize + 1
        )
        #expect(throws: ConfigurationBackupError.fileTooLarge) {
            try ConfigurationBackupCodec.decrypt(oversized, password: password)
        }
    }

    @Test("Treats password whitespace and Unicode as exact input")
    func preservesExactPasswordInput() throws {
        let exactPassword = "  密码 passphrase  "
        let encrypted = try ConfigurationBackupCodec.encrypt(
            makePayload(),
            password: exactPassword,
            salt: fixedSalt,
            nonce: fixedNonce
        )

        _ = try ConfigurationBackupCodec.decrypt(encrypted, password: exactPassword)
        #expect(throws: ConfigurationBackupError.authenticationFailed) {
            try ConfigurationBackupCodec.decrypt(encrypted, password: exactPassword.trim())
        }
    }

    // MARK: Private

    private let password = "correct horse battery staple"
    private let fixedSalt = Data((0 ..< ConfigurationBackupCodec.saltLength).map(UInt8.init))
    private let fixedNonce = Data((0 ..< ConfigurationBackupCodec.nonceLength).map { UInt8($0 + 40) })

    private func fixedEncryptedBackup() throws -> Data {
        try ConfigurationBackupCodec.encrypt(
            makePayload(),
            password: password,
            salt: fixedSalt,
            nonce: fixedNonce
        )
    }

    private func makePayload(
        credentialCanary: String = "FAKE_CREDENTIAL_FOR_TESTING_ONLY",
        descriptorCanary: String = "credential.test.api-key"
    )
        -> ConfigurationBackupPayload {
        ConfigurationBackupPayload(
            schemaVersion: ConfigurationBackupPayload.schemaVersion,
            bundleIdentifier: "com.example.easydict-tests",
            applicationVersion: "1.0",
            applicationBuild: "100",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            items: [
                ConfigurationBackupItem(
                    descriptor: .init(name: "setting.appearance"),
                    valueKind: .string,
                    value: Data("system".utf8)
                ),
                ConfigurationBackupItem(
                    descriptor: .init(name: descriptorCanary),
                    valueKind: .string,
                    value: Data(credentialCanary.utf8)
                ),
            ]
        )
    }

    private func assertEqual(
        _ actual: ConfigurationBackupPayload,
        _ expected: ConfigurationBackupPayload
    ) {
        #expect(actual.schemaVersion == expected.schemaVersion)
        #expect(actual.bundleIdentifier == expected.bundleIdentifier)
        #expect(actual.applicationVersion == expected.applicationVersion)
        #expect(actual.applicationBuild == expected.applicationBuild)
        #expect(actual.createdAt == expected.createdAt)
        #expect(actual.items.count == expected.items.count)
        for (actualItem, expectedItem) in zip(actual.items, expected.items) {
            #expect(actualItem.descriptor == expectedItem.descriptor)
            #expect(actualItem.valueKind == expectedItem.valueKind)
            #expect(actualItem.value == expectedItem.value)
        }
    }
}
