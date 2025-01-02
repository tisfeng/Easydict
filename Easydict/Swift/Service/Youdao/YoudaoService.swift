//
//  YoudaoService.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import CryptoSwift
import Foundation

// MARK: - Constants

let kYoudaoTranslateURL = "https://fanyi.youdao.com"
let kYoudaoDictURL = "https://dict.youdao.com"

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

    let session: Session

    var headers: HTTPHeaders {
        [
            "User-Agent": EZUserAgent,
            "Referer": kYoudaoTranslateURL,
            "Content-Type": "application/x-www-form-urlencoded",
            "Cookie": cookie,
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

    // MARK: Private

    /// Note: The official Youdao API supports most languages, but its web page shows that only 15 languages are supported. https://fanyi.youdao.com/index.html#/
    private var languagesDictionary: [Language: String] {
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

    private func requestYoudaoCookie() {
        // https://fanyi.youdao.com/index.html#/
        let cookieURL = kYoudaoTranslateURL + "/index.html#/"
        CookieManager.shared.requestCookie(ofURL: cookieURL, cookieName: "OUTFOX_SEARCH_USER_ID") { cookie in
            if let cookie = cookie {
                UserDefaults.standard.set(cookie, forKey: kYoudaoTranslateURL)
            }
        }
    }
}
