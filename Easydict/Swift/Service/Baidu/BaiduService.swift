//
//  BaiduService.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import SwiftUI

let kBaiduTranslateURL = "https://fanyi.baidu.com"

// MARK: - BaiduService

@objc(EZBaiduTranslate)
@objcMembers
final class BaiduService: QueryService {
    // MARK: Public

    /// Returns configuration items for the Baidu service settings view.
    public override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.app_id.title",
                key: .baiduAppId
            )

            SecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.secret_key.title",
                key: .baiduSecretKey
            )
        }
    }

    // MARK: Internal

    // MARK: - Overrides

    override func resultDidUpdate(_ result: QueryResult) {
        super.resultDidUpdate(result)
        apiTranslate.result = result
    }

    override func serviceType() -> ServiceType {
        .baidu
    }

    override func supportedQueryType() -> EZQueryTextType {
        let defaultType: EZQueryTextType = [.dictionary, .sentence, .translation]
        let configured = Configuration.shared.queryTextTypeForServiceType(serviceType())
        return configured.isEmpty ? defaultType : configured
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func name() -> String {
        NSLocalizedString("baidu_translate", comment: "")
    }

    override func link() -> String {
        kBaiduTranslateURL
    }

    override func wordLink(_ queryModel: QueryModel) -> String? {
        guard let from = languageCode(forLanguage: queryModel.queryFromLanguage),
              let to = languageCode(forLanguage: queryModel.queryTargetLanguage) else {
            return nil
        }

        let encodedText = queryModel.queryText.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""
        return "\(kBaiduTranslateURL)/#\(from)/\(to)/\(encodedText)"
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let orderedDict = MMOrderedDictionary()
        let items: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh",
            Language.classicalChinese, "wyw",
            Language.traditionalChinese, "cht",
            Language.english, "en",
            Language.japanese, "jp",
            Language.korean, "kor",
            Language.french, "fra",
            Language.spanish, "spa",
            Language.portuguese, "pt",
            Language.brazilianPortuguese, "pot",
            Language.italian, "it",
            Language.german, "de",
            Language.russian, "ru",
            Language.arabic, "ara",
            Language.swedish, "swe",
            Language.romanian, "rom",
            Language.thai, "th",
            Language.slovak, "slo",
            Language.dutch, "nl",
            Language.hungarian, "hu",
            Language.greek, "el",
            Language.danish, "dan",
            Language.finnish, "fin",
            Language.polish, "pl",
            Language.czech, "cs",
            Language.turkish, "tr",
            Language.lithuanian, "lit",
            Language.latvian, "lav",
            Language.ukrainian, "ukr",
            Language.bulgarian, "bul",
            Language.indonesian, "id",
            Language.malay, "msa",
            Language.slovenian, "slv",
            Language.estonian, "est",
            Language.vietnamese, "vie",
            Language.persian, "per",
            Language.hindi, "hin",
            Language.telugu, "tel",
            Language.tamil, "tam",
            Language.urdu, "urd",
            Language.filipino, "fil",
            Language.khmer, "khm",
            Language.lao, "lo",
            Language.bengali, "ben",
            Language.burmese, "bur",
            Language.norwegian, "nor",
            Language.serbian, "srp",
            Language.croatian, "hrv",
            Language.mongolian, "mon",
            Language.hebrew, "heb",
            Language.georgian, "geo",
        ]

        for index in stride(from: 0, to: items.count, by: 2) {
            let key = items[index]
            if index + 1 < items.count {
                let value = items[index + 1]
                if let key = key as? NSCopying {
                    orderedDict.setObject(value, forKey: key)
                }
            }
        }

        return orderedDict
    }

    /// Translate text using the Baidu API.
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        guard !text.isEmpty else {
            throw QueryError.error(type: .parameter, message: "翻译的文本为空")
        }

        let trimmedText = (text as NSString).ns_trimToMaxLength(5000) as String
        apiTranslate.result = result
        let fromCode = languageCode(forLanguage: from).map(Language.init(rawValue:)) ?? from
        let toCode = languageCode(forLanguage: to).map(Language.init(rawValue:)) ?? to

        return try await withCheckedThrowingContinuation { continuation in
            apiTranslate.translate(trimmedText, from: fromCode, to: toCode) { [weak self] result, error in
                guard let self else {
                    continuation.resume(
                        throwing: QueryError.error(
                            type: .unknown,
                            message: "Service released before completing the request"
                        )
                    )
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result ?? self.result ?? QueryResult())
                }
            }
        }
    }

    /// Detect language using the Baidu API.
    @nonobjc
    override func detectText(_ text: String) async throws -> Language {
        guard !text.isEmpty else {
            throw QueryError.error(type: .parameter, message: "识别语言的文本为空")
        }

        do {
            let languge = try await requestDetectedLanguage(for: text)
            return languge
        } catch {
            throw error as? QueryError ?? QueryError.error(type: .api, message: "判断语言失败")
        }
    }

    /// Generate audio URL for Baidu TTS.
    override func textToAudio(
        _ text: String,
        fromLanguage: Language,
        accent: String?
    ) async throws
        -> String? {
        guard !text.isEmpty else {
            throw QueryError.error(type: .parameter, message: "获取音频的文本为空")
        }

        if fromLanguage == .auto {
            let detectedLanguage = try await detectText(text)
            return getAudioURL(
                with: text,
                langCode: getTTSLanguageCode(detectedLanguage, accent: accent)
            )
        }

        return getAudioURL(
            with: text,
            langCode: getTTSLanguageCode(fromLanguage, accent: accent)
        )
    }

    override func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        if language == .english {
            return accent == "uk" ? "uk" : "en"
        }
        return super.getTTSLanguageCode(language, accent: accent)
    }

    // MARK: - OCR

    override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        try await performBaiduOCR(image, from: from, to: to)
    }

    override func ocrAndTranslate(
        _ image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> ()
    ) async throws
        -> (EZOCRResult?, QueryResult?) {
        guard let ocrResult = try await ocr(image, from: from, to: to) else {
            return (nil, nil)
        }

        ocrSuccess(ocrResult, true)
        let result = try await translate(ocrResult.mergedText, from: from, to: to)
        return (ocrResult, result)
    }

    /// Detect language for Objective-C callers without creating nested async tasks.
    override func detectText(
        _ text: String,
        completionHandler: @escaping (Language, Error?) -> ()
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let language = try await detectText(text)
                await MainActor.run {
                    completionHandler(language, nil)
                }
            } catch {
                await MainActor.run {
                    completionHandler(.auto, error)
                }
            }
        }
    }

    func getAudioURL(with text: String, langCode: String) -> String {
        let trimmed = (text as NSString).ns_trimToMaxLength(1000) as String
        let encoded = trimmed.ns_encode() as String

        let speed = (langCode == "zh") ? 5 : 3
        return "\(kBaiduTranslateURL)/gettts?text=\(encoded)&lan=\(langCode)&spd=\(speed)&source=web"
    }

    // MARK: Private

    // MARK: - Private properties

    private lazy var apiTranslate: BaiduApiTranslate = {
        BaiduApiTranslate(queryModel: queryModel ?? QueryModel())
    }()

    /// Requests detected language for the given text.
    private func requestDetectedLanguage(for text: String) async throws -> Language {
        let queryString = (text as NSString).ns_trimToMaxLength(73) as String
        let url = "\(kBaiduTranslateURL)/langdetect"

        do {
            let response = try await AF.request(
                url,
                method: .post,
                parameters: ["query": queryString],
                encoder: URLEncodedFormParameterEncoder.default
            )
            .validate()
            .serializingDecodable(BaiduDetectResponse.self)
            .value

            guard let from = response.lan, !from.isEmpty else {
                throw QueryError.error(type: .unsupportedLanguage)
            }

            return languageEnum(fromCode: from)
        } catch let decodingError as DecodingError {
            logError("Baidu language detection response parsing error: \(decodingError)")
            throw QueryError.error(type: .api, message: "判断语言失败")
        } catch let queryError as QueryError {
            throw queryError
        } catch {
            throw QueryError.error(type: .api, message: "判断语言失败")
        }
    }
}

// MARK: - BaiduDetectResponse

/// Response payload for Baidu language detection.
private struct BaiduDetectResponse: Decodable {
    let lan: String?
}
