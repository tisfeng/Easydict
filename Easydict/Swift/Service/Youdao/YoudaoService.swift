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
                    throw TranslateError.emptyText
                }

                let result = try await queryYoudaoDictAndTranslation(text: text, from: from, to: to)
                completion(result, nil)
            } catch {
                completion(result, error)
            }
        }
    }

    override func detectText(_ text: String, completion: @escaping (Language, (any Error)?) -> ()) {
        Task {
            do {
                guard !text.isEmpty else {
                    throw TranslateError.emptyText
                }

                let queryString = String(text.prefix(73))
                let result = try await translate(queryString, from: .auto, to: .auto)
                completion(result.from, nil)
            } catch {
                completion(.auto, error)
            }
        }
    }

    override func text(
        toAudio text: String,
        fromLanguage from: Language,
        completion: @escaping (String?, (any Error)?) -> ()
    ) {
        Task {
            do {
                guard !text.isEmpty else {
                    throw TranslateError.emptyText
                }

                let language = getTTSLanguageCode(from)
                let encodedText =
                    text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let audioURL = "\(kYoudaoDictURL)/dictvoice?audio=\(encodedText)&le=\(language)"
                completion(audioURL, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    override func getTTSLanguageCode(_ language: Language) -> String {
        // Implement TTS language code conversion
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
            throw TranslateError.emptyText
        }

        if queryTextType().isEmpty {
            throw TranslateError.noResultsFound
        }

        _ = try await webTranslate(text: text, from: from, to: to)

//        async let dictResult = queryYoudaoDict(text: text, from: from, to: to)
//
//        if queryTextType().contains(.translation) {
//            async let translateResult = webTranslate(text: text, from: from, to: to)
//            _ = try await [dictResult, translateResult]
//        } else {
//            _ = try await dictResult
//        }

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
            throw TranslateError.apiError("Invalid language code")
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
               let decodedData = decodeAES128(stringData)?.data(using: .utf8) {
                let response = try JSONDecoder().decode(YoudaoTranslateResponse.self, from: decodedData)
                if response.code == 0 {
                    // Flatten the nested arrays and join translations
                    result.translatedResults = response.translateResult.map { group in
                        group.map(\.tgt).joined(separator: "\n")
                    }
                    result.raw = response
                } else {
                    throw TranslateError.apiError("Translation failed with code: \(response.code)")
                }
            } else {
                throw TranslateError.apiError("Failed to decode response data")
            }
        } catch {
            throw TranslateError.apiError("Failed to parse response: \(error.localizedDescription)")
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
            throw TranslateError.emptyText
        }

        guard !queryTextType().isEmpty else {
            return result
        }

        let enableDictionary = queryTextType().contains(.dictionary)

        guard let foreignLanguage = youdaoDictForeignLanguage(queryModel),
              enableDictionary
        else {
            throw TranslateError.noResultsFound
        }

        // Prepare dictionary query parameters
        let dicts = [["web_trans", "ec", "ce", "newhh", "baike", "wikipedia_digest"]]
        let dictsParams =
            [
                "count": 99,
                "dicts": dicts,
            ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: dictsParams)
        guard let dictsString = String(data: jsonData, encoding: .utf8) else {
            throw TranslateError.apiError("Failed to encode dicts parameters")
        }

        let parameters = [
            "q": text,
            "le": foreignLanguage,
            "dicts": dictsString,
        ]

        let url = "\(kYoudaoDictURL)/jsonapi"

        do {
            let response = try await session.request(
                url,
                method: .get,
                parameters: parameters
            )
            .serializingDecodable(YoudaoDictModel.self)
            .value

            // Update result with dictionary response
            updateResult(with: response)
            return result

        } catch {
            throw TranslateError.networkError(error)
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

    private func updateResult(with dictModel: YoudaoDictModel) {
        // Implement result update logic based on dictionary model
        // This should mirror the Objective-C implementation of setupWithYoudaoDictModel:
    }
}

func decodeAES128(_ t: String) -> String? {
    let key = "ydsecret://query/key/B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl"
    let lv = "ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4"

    guard let keyData = key.data(using: .utf8),
          let lvData = lv.data(using: .utf8) else {
        return nil
    }

    let base64String = t.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    guard let tData = Data(base64Encoded: base64String) else {
        return nil
    }

    let fo = Insecure.MD5.hash(data: keyData)
    let fn = Insecure.MD5.hash(data: lvData)

    let a = Data(fo)
    let i = Data(fn)

    do {
        let aes = try AES(key: [UInt8](a), blockMode: CBC(iv: [UInt8](i)), padding: .pkcs7)
        let decryptedData = try aes.decrypt([UInt8](tData))
        return String(data: Data(decryptedData), encoding: .utf8)
    } catch {
        print("Error decrypting: \(error)")
        return nil
    }
}

// MARK: - YoudaoTranslateResponse

struct YoudaoTranslateResponse: Codable {
    struct TranslateResultItem: Codable {
        let src: String
        let tgt: String
        let tgtPronounce: String?
    }

    let translateResult: [[TranslateResultItem]]
    let type: String // en2zh-CHS
    let code: Int
    let dictResult: YoudaoDictModel?
}

// MARK: - YoudaoDictModel

struct YoudaoDictModel: Codable {
    enum CodingKeys: String, CodingKey {
        case ec
    }

    let ec: EC?
}

// MARK: - EC

struct EC: Codable {
    enum CodingKeys: String, CodingKey {
        case examType = "exam_type"
        case word
    }

    let examType: [String]?
    let word: ECWord?
}

// MARK: - ECWord

struct ECWord: Codable {
    enum CodingKeys: String, CodingKey {
        case prototype
        case returnPhrase = "return-phrase"
        case trs, ukphone, ukspeech, usphone, usspeech, wfs
    }

    let prototype: String?
    let returnPhrase: String?
    let trs: [ECTrs]?
    let ukphone: String?
    let ukspeech: String?
    let usphone: String?
    let usspeech: String?
    let wfs: [ECWordForm]?
}

// MARK: - ECTrs

struct ECTrs: Codable {
    let pos: String?
    let tran: String?
}

// MARK: - ECWordForm

struct ECWordForm: Codable {
    struct WordForm: Codable {
        let name: String
        let value: String
    }

    let wf: WordForm
}

// MARK: - TranslateError

enum TranslateError: LocalizedError {
    case emptyText
    case noResultsFound
    case networkError(Error)
    case apiError(String)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .emptyText:
            "Translation text is empty"
        case .noResultsFound:
            "No results found"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .apiError(message):
            "API error: \(message)"
        }
    }
}
