//
//  YoudaoService.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright 2025 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import CryptoSwift
import Foundation

// MARK: - Constants

private let kYoudaoTranslateURL = "https://fanyi.youdao.com"
private let kYoudaoDictURL = "https://dict.youdao.com"

// MARK: - YoudaoService

@objc(EZYoudaoService)
final class YoudaoService: QueryService {
    // MARK: Lifecycle

    override init() {
        let configuration = URLSessionConfiguration.default
        self.session = Session(configuration: configuration)
        super.init()

        configuration.headers = headers
    }

    // MARK: Internal

    // MARK: - Initialization

    var headers: HTTPHeaders {
        [
            "User-Agent": EZUserAgent,
            "Referer": kYoudaoTranslateURL,
            "Content-Type": "application/x-www-form-urlencoded",
            "Cookie": cookie,
        ]
    }

    /// Note: The official Youdao API supports most languages, but its web page shows that only 15 languages are supported. https://fanyi.youdao.com/index.html#/
    var languagesDictionary: [Language: String] {
        [
            .simplifiedChinese: "zh-CHS",
            .traditionalChinese: "zh-CHT",
            .english: "en",
            .japanese: "ja",
            .korean: "ko",
            .french: "fr",
            .spanish: "es",
            .portuguese: "pt",
            .italian: "it",
            .german: "de",
            .russian: "ru",
            .arabic: "ar",
            .thai: "th",
            .dutch: "nl",
            .indonesian: "id",
            .vietnamese: "vi",
        ]
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for (key, value) in languagesDictionary {
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override func link() -> String {
        kYoudaoTranslateURL
    }

    override func name() -> String {
        NSLocalizedString("youdao_dict", comment: "")
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func queryTextType() -> EZQueryTextType {
        [.dictionary, .sentence, .translation]
    }

    override func serviceType() -> ServiceType {
        .youdao
    }

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        Task {
            do {
                guard !text.isEmpty else {
                    throw QueryError(type: .parameter, message: "Translation text is empty")
                }

                let result = try await queryYoudaoDictAndTranslation(text: text, from: from, to: to)
                completion(result, nil)
            } catch {
                completion(result, error)
            }
        }
    }

    override func text(
        toAudio text: String,
        fromLanguage from: Language,
        completion: @escaping (String?, (any Error)?) -> ()
    ) {
        guard !text.isEmpty else {
            return completion(
                nil, QueryError(type: .parameter, message: "Translation text is empty")
            )
        }

        let language = getTTSLanguageCode(from)
        let encodedText =
            text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let audioURL = "\(kYoudaoDictURL)/dictvoice?audio=\(encodedText)&le=\(language)"
        completion(audioURL, nil)
    }

    override func getTTSLanguageCode(_ language: Language) -> String {
        languageCode(forLanguage: language) ?? ""
    }

    // MARK: Private

    // MARK: - Properties

    private let session: Session

    private var cookie: String {
        if let cookie = UserDefaults.standard.string(forKey: kYoudaoTranslateURL) {
            return cookie
        }
        let defaultCookie =
            "OUTFOX_SEARCH_USER_ID=833782676@113.88.171.235; domain=.youdao.com; expires=2052-12-31 13:12:38 +0000"
        UserDefaults.standard.set(defaultCookie, forKey: kYoudaoTranslateURL)
        requestYoudaoCookie()
        return defaultCookie
    }

    // MARK: - Private Methods

    private func queryYoudaoDictAndTranslation(
        text: String,
        from: Language,
        to: Language
    ) async throws
        -> EZQueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        if queryTextType().isEmpty {
            throw QueryError(type: .unsupported, message: "No results found")
        }

        async let dictResult = queryYoudaoDict(text: text, from: from, to: to)
        async let translateResult = webTranslate(text: text, from: from, to: to)
        _ = try await [dictResult, translateResult]

        return result
    }

    private func webTranslate(text: String, from: Language, to: Language) async throws
        -> EZQueryResult {
        let client = "fanyideskweb"
        let product = "webfanyi"
        let key = "Vy4EQ1uwPkUoqvcP1nIu6WiAjxFeA3Ye"
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        let sign = generateSign(client: client, timestamp: timestamp, product: product, key: key)
        let fromCode = languageCode(forLanguage: from)
        let toCode = languageCode(forLanguage: to)

        guard let fromCode = fromCode, let toCode = toCode else {
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
                type: .api, message: "Failed to parse response: \(error.localizedDescription)"
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

    private func requestYoudaoCookie() {
        // https://fanyi.youdao.com/index.html#/
        let cookieURL = kYoudaoTranslateURL + "/index.html#/"
        CookieManager.shared.requestCookie(ofURL: cookieURL, cookieName: "OUTFOX_SEARCH_USER_ID") { cookie in
            if let cookie = cookie {
                UserDefaults.standard.set(cookie, forKey: kYoudaoTranslateURL)
            }
        }
    }

    private func queryYoudaoDict(text: String, from: Language, to: Language) async throws
        -> EZQueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        guard !queryTextType().isEmpty else {
            return result
        }

        let enableDictionary = queryTextType().contains(.dictionary)

        guard let foreignLanguage = youdaoDictForeignLanguage(queryModel),
              enableDictionary
        else {
            throw QueryError(type: .unsupported, message: "No results found")
        }

        /**
         dicts can be empty, means all dictionaries.

         dicts values from response meta.dicts, for example:

         web_trans, oxfordAdvanceHtml, video_sents, simple, phrs, oxford, syno, collins, word_video, webster, discriminate, ec, ee, blng_sents_part, individual, collins_primary, rel_word, auth_sents_part, media_sents_part, expand_ec, etym, special, senior, music_sents, baike, meta, oxfordAdvance
         */
        let dicts = [["web_trans", "ec", "ce", "newhh", "baike", "wikipedia_digest", "fanyi"]]
        let dictsParams =
            [
                "count": 99,
                "dicts": dicts,
            ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: dictsParams)
        let dictsString = String(data: jsonData, encoding: .utf8) ?? ""

        let parameters = [
            "q": text,
            "le": foreignLanguage,
            "dicts": dictsString, // dicts can be empty, means all dictionaries
        ]

        let url = "\(kYoudaoDictURL)/jsonapi"

        do {
            // Get the raw data
            let responseData = try await session.request(
                url,
                method: .get,
                parameters: parameters
            )
            .serializingData()
            .value

            // Decode the data
            let response = try JSONDecoder().decode(YoudaoDictResponse.self, from: responseData)
            result.update(with: response)
            return result
        } catch {
            throw QueryError(
                type: .api,
                message: "Failed to query Youdao dictionary: \(String(describing: error))"
            )
        }
    }

    private func youdaoDictForeignLanguage(_ queryModel: EZQueryModel) -> String? {
        let fromLanguage = queryModel.queryFromLanguage
        let toLanguage = queryModel.queryTargetLanguage

        let supportedLanguages: [Language] = [.english, .japanese, .french, .korean]

        var foreignLanguage: String?

        if fromLanguage.isKindOfChinese() {
            foreignLanguage = languageCode(forLanguage: toLanguage)
        } else if toLanguage.isKindOfChinese() {
            foreignLanguage = languageCode(forLanguage: fromLanguage)
        }

        let supportedCodes = supportedLanguages.map { languageCode(forLanguage: $0) }
        return supportedCodes.contains(foreignLanguage ?? "") ? foreignLanguage : nil
    }
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
