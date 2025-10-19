//
//  YoudaoService+Translate.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import CryptoSwift
import Foundation

// MARK: - YoudaoService+Translate

// TODO: move translate api to a independent class instead of extension.
extension YoudaoService {
    // MARK: - Constants

    private enum Constants {
        static let client = "fanyideskweb"
        static let product = "webfanyi"

        static let appVersion = "1.0.0"
        static let vendor = "web"
        static let pointParam = "client,mysticTime,product"
        static let keyfrom = "fanyi.web"

        // For get youdao key
        static let defaultKey = "asdjnjfenknafdfsdfsd"
    }

    private var generalParameters: Parameters {
        [
            "client": Constants.client,
            "product": Constants.product,
            "appVersion": Constants.appVersion,
            "vendor": Constants.vendor,
            "pointParam": Constants.pointParam,
            "keyfrom": Constants.keyfrom,

            "keyid": "",
            "sign": "",
            "mysticTime": "",
        ]
    }

    func webTranslate(text: String, from: Language, to: Language) async throws
        -> EZQueryResult {
        let key = try await getYoudaoKey()
        let aesKey = key.data.aesKey
        let aesIv = key.data.aesIv
        let secretKey = key.data.secretKey

        let timestamp = currentTimestamp()
        let sign = generateSign(
            client: Constants.client,
            timestamp: timestamp,
            product: Constants.product,
            key: secretKey
        )

        let fromCode = languageCode(forLanguage: from)
        let toCode = languageCode(forLanguage: to)

        guard let fromCode, let toCode else {
            throw QueryError(type: .api, message: "Invalid language code")
        }

        var parameters = generalParameters
        parameters.merge(
            [
                "i": text,
                "from": fromCode,
                "to": toCode,
                "dictResult": "false",
                "keyid": "webfanyi",
                "sign": sign,
                "mysticTime": timestamp,
            ], uniquingKeysWith: { _, new in new }
        )

        let data = try await AF.request(
            "\(kYoudaoDictURL)/webtranslate",
            method: .post,
            parameters: parameters,
            headers: headers
        )
        .serializingData()
        .value

        do {
            let translateResponse = try parseTranslationResult(data, aesKey: aesKey, aesIv: aesIv)
            try updateResult(translateResponse: translateResponse)
        } catch {
            throw QueryError(
                type: .api, message: "Failed to parse response: \(error)"
            )
        }

        return result
    }

    /// Get secret key from Youdao web
    /// Refer: https://github.com/HolynnChen/somejs/blob/5c74682faccaa17d52740e7fe285d13de3c32dba/translate.js#L717
    private func getYoudaoKey() async throws -> YoudaoKey {
        let timestamp = currentTimestamp()
        let sign = generateSign(
            client: Constants.client,
            timestamp: timestamp,
            product: Constants.product,
            key: Constants.defaultKey
        )

        var parameters = generalParameters
        parameters.merge(
            [
                "keyid": "webfanyi-key-getter",
                "sign": sign,
                "mysticTime": timestamp,
            ], uniquingKeysWith: { _, new in new }
        )

        return try await AF.request(
            "\(kYoudaoDictURL)/webtranslate/key",
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .serializingDecodable(YoudaoKey.self)
        .value
    }

    private func generateSign(
        client: String,
        timestamp: String,
        product: String,
        key: String
    )
        -> String {
        let signText = "client=\(client)&mysticTime=\(timestamp)&product=\(product)&key=\(key)"
        return signText.md5()
    }

    /// AES-128-CBC decryption with PKCS7 padding
    /// - Parameters:
    ///   - encryptedText: Base64 encoded encrypted text with URL-safe characters (- and _)
    ///   - key: The key used for encryption
    ///   - iv: The initialization vector used for encryption
    /// - Returns: Decrypted string if successful, nil otherwise
    /// - Note: From https://github.com/blance714/StaticeApp/blob/a8706aaf4806468a663d7986b901b09be5fc9319/Statice/Model/Search/Youdao.swift
    private func decryptAES128CBC(
        encryptedText: String,
        key: String,
        iv: String
    )
        -> String? {
        // Convert key and iv to UTF-8 data
        guard let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8)
        else {
            logError("Failed to convert key or iv to data")
            return nil
        }

        // Convert URL-safe base64 to standard base64
        let standardBase64 =
            encryptedText
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")

        // Decode base64 string to data
        guard let encryptedData = Data(base64Encoded: standardBase64) else {
            logError("Failed to decode base64 string")
            return nil
        }

        // Generate MD5 hashes for key and iv
        let keyHash = Insecure.MD5.hash(data: keyData)
        let ivHash = Insecure.MD5.hash(data: ivData)

        // Convert hashes to Data
        let keyHashData = Data(keyHash)
        let ivHashData = Data(ivHash)

        do {
            // Create AES cipher with CBC mode and PKCS7 padding
            let cipher = try AES(
                key: [UInt8](keyHashData),
                blockMode: CBC(iv: [UInt8](ivHashData)),
                padding: .pkcs7
            )

            // Decrypt the data
            let decryptedBytes = try cipher.decrypt([UInt8](encryptedData))

            // Convert decrypted bytes to string
            guard let decryptedString = String(data: Data(decryptedBytes), encoding: .utf8) else {
                logError("Failed to convert decrypted data to string")
                return nil
            }

            return decryptedString

        } catch {
            logError("AES decryption error: \(error)")
            return nil
        }
    }

    /// A timestamp string in milliseconds, for example, "1735872379000".
    private func currentTimestamp() -> String {
        String(Int(Date().timeIntervalSince1970 * 1000))
    }

    /// Parse translation result from Youdao web
    private func parseTranslationResult(
        _ data: Data,
        aesKey: String,
        aesIv: String
    ) throws
        -> YoudaoTranslateResponse {
        if let encryptedText = String(data: data, encoding: .utf8),
           let decodedData = decryptAES128CBC(
               encryptedText: encryptedText,
               key: aesKey,
               iv: aesIv
           )?.data(using: .utf8) {
            let response = try JSONDecoder().decode(
                YoudaoTranslateResponse.self, from: decodedData
            )
            return response
        } else {
            throw QueryError(type: .api, message: "Failed to decode response data")
        }
    }

    private func updateResult(translateResponse: YoudaoTranslateResponse) throws {
        if translateResponse.code == 0 {
            // Flatten the nested arrays and join translations
            let translations = translateResponse.translateResult.map { group in
                group.map { $0.tgt }.joined(separator: "")
            }
            let translatedText = translations.joined(separator: "")
            result.translatedResults = translatedText.split(
                separator: "\n", omittingEmptySubsequences: false
            )
            .map { String($0) }
            result.raw = translateResponse
        } else {
            throw QueryError(
                type: .api, message: "Translation failed with code: \(translateResponse.code)"
            )
        }
    }
}
