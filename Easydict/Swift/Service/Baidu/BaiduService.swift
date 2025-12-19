//
//  BaiduService.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire

let kBaiduTranslateURL = "https://fanyi.baidu.com"

// MARK: - BaiduService

@objc(EZBaiduTranslate)
@objcMembers
final class BaiduService: QueryService {
    // MARK: Internal

    // MARK: - Overrides

    override func resultDidUpdate(_ result: EZQueryResult) {
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

    override func wordLink(_ queryModel: EZQueryModel) -> String? {
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

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(result, QueryError.error(type: .parameter, message: "翻译的文本为空"))
            return
        }

        let trimmedText = (text as NSString).ns_trimToMaxLength(5000) as String
        apiTranslate.result = result
        let fromCode = languageCode(forLanguage: from).map(Language.init(rawValue:)) ?? from
        let toCode = languageCode(forLanguage: to).map(Language.init(rawValue:)) ?? to

        apiTranslate.translate(trimmedText, from: fromCode, to: toCode) { [weak self] result, error in
            guard let self else { return }
            completion(result ?? self.result, error)
        }
    }

    override func detectText(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(.auto, QueryError.error(type: .parameter, message: "识别语言的文本为空"))
            return
        }

        let queryString = (text as NSString).ns_trimToMaxLength(73) as String
        let url = "\(kBaiduTranslateURL)/langdetect"

        AF.request(
            url,
            method: .post,
            parameters: ["query": queryString],
            encoder: URLEncodedFormParameterEncoder.default
        )
        .validate()
        .responseJSON { [weak self] response in
            guard let self else { return }
            switch response.result {
            case let .success(value):
                if let json = value as? [String: Any] {
                    if let from = json["lan"] as? String, !from.isEmpty {
                        completion(languageEnum(fromCode: from), nil)
                    } else {
                        completion(.auto, QueryError.error(type: .unsupportedLanguage))
                    }
                    return
                }
                completion(.auto, QueryError.error(type: .api, message: "判断语言失败"))
            case .failure:
                completion(.auto, QueryError.error(type: .api, message: "判断语言失败"))
            }
        }
    }

    override func textToAudio(
        _ text: String,
        fromLanguage: Language,
        accent: String?,
        completion: @escaping (String?, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(nil, QueryError.error(type: .parameter, message: "获取音频的文本为空"))
            return
        }

        if fromLanguage == .auto {
            detectText(text) { [weak self] detectedLanguage, error in
                guard let self else { return }
                if let error {
                    completion(nil, error)
                } else {
                    let url = getAudioURL(with: text, langCode: getTTSLanguageCode(detectedLanguage, accent: accent))
                    completion(url, nil)
                }
            }
        } else {
            let url = getAudioURL(with: text, langCode: getTTSLanguageCode(fromLanguage, accent: accent))
            completion(url, nil)
        }
    }

    override func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        if language == .english {
            return accent == "uk" ? "uk" : "en"
        }
        return super.getTTSLanguageCode(language, accent: accent)
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
        BaiduApiTranslate(queryModel: queryModel ?? EZQueryModel())
    }()
}
