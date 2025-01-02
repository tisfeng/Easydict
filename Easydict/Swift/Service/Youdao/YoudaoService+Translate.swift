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

extension YoudaoService {
    func queryYoudaoDictAndTranslation(
        text: String,
        from: Language,
        to: Language
    ) async throws
        -> EZQueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        async let dictResult = queryYoudaoDict(text: text, from: from, to: to)
        async let translateResult = webTranslate(text: text, from: from, to: to)
        _ = try await [dictResult, translateResult]

        return result
    }

    /// Youdao web translate API. Ref: https://github.com/blance714/StaticeApp/blob/a8706aaf4806468a663d7986b901b09be5fc9319/Statice/Model/Search/Youdao.swift
    private func webTranslate(text: String, from: Language, to: Language) async throws
        -> EZQueryResult {
        let client = "fanyideskweb"
        let product = "webfanyi"
        let key = "Vy4EQ1uwPkUoqvcP1nIu6WiAjxFeA3Ye"
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        let sign = generateSign(client: client, timestamp: timestamp, product: product, key: key)
        let fromCode = languageCode(forLanguage: from)
        let toCode = languageCode(forLanguage: to)

        guard let fromCode, let toCode else {
            throw QueryError(type: .api, message: "Invalid language code")
        }

        let parameters: [String: Any] = [
            "i": text,
            "from": fromCode,
            "to": toCode,
            "dictResult": "true",
            "keyid": product,
            "sign": sign,
            "client": client,
            "product": product,
            "appVersion": "1.1.0",
            "vendor": "web",
            "pointParam": "client,mysticTime,product",
            "mysticTime": timestamp,
            "keyfrom": "fanyi.web",
        ]

        let data = try await AF.request(
            "\(kYoudaoDictURL)/webtranslate",
            method: .post,
            parameters: parameters,
            headers: headers
        )
        .serializingData()
        .value

        do {
            if let stringData = String(data: data, encoding: .utf8),
               let decodedData = decryptAES128CBC(encryptedText: stringData)?.data(using: .utf8) {
                let response = try JSONDecoder().decode(
                    YoudaoTranslateResponse.self, from: decodedData
                )
                if response.code == 0 {
                    // Flatten the nested arrays and join translations
                    let translations = response.translateResult.map { group in
                        group.map(\.tgt).joined(separator: "")
                    }
                    let translatedText = translations.joined(separator: "")
                    result.translatedResults = translatedText.split(
                        separator: "\n", omittingEmptySubsequences: false
                    )
                    .map { String($0) }
                    result.raw = response
                } else {
                    throw QueryError(
                        type: .api, message: "Translation failed with code: \(response.code)"
                    )
                }
            } else {
                throw QueryError(type: .api, message: "Failed to decode response data")
            }
        } catch {
            throw QueryError(
                type: .api, message: "Failed to parse response: \(String(describing: error))"
            )
        }

        return result
    }

    private func generateSign(
        client: String,
        timestamp: String,
        product: String,
        key: String
    )
        -> String {
        let signText = "client=\(client)&mysticTime=\(timestamp)&product=\(product)&key=\(key)"
        let sign = signText.md5()
        return sign
    }

    /// AES-128-CBC decryption with PKCS7 padding
    /// - Parameters:
    ///   - encryptedText: Base64 encoded encrypted text with URL-safe characters (- and _)
    ///   - key: The key used for encryption
    ///   - iv: The initialization vector used for encryption
    /// - Returns: Decrypted string if successful, nil otherwise
    private func decryptAES128CBC(
        encryptedText: String,
        key: String =
            "ydsecret://query/key/B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl",
        iv: String =
            "ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4"
    )
        -> String? {
        // Convert key and iv to UTF-8 data
        guard let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8)
        else {
            print("Failed to convert key or iv to data")
            return nil
        }

        // Convert URL-safe base64 to standard base64
        let standardBase64 =
            encryptedText
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")

        // Decode base64 string to data
        guard let encryptedData = Data(base64Encoded: standardBase64) else {
            print("Failed to decode base64 string")
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
                print("Failed to convert decrypted data to string")
                return nil
            }

            return decryptedString

        } catch {
            print("AES decryption error: \(error)")
            return nil
        }
    }
}
