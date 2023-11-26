//
//  TencentService.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import Foundation

@objc(EZTencentService)
public final class TencentService: QueryService {
    override public func serviceType() -> ServiceType {
        .tencent
    }

    override public func link() -> String? {
        "https://fanyi.qq.com"
    }

    override public func name() -> String {
        NSLocalizedString("tencent_translate", comment: "The name of Tencent Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary in the API
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        let dic: [Language: String] = [
            .auto: "auto",
            .simplifiedChinese: "zh",
            .traditionalChinese: "zh-TW",
            .english: "en",
            .japanese: "ja",
            .korean: "ko",
            .french: "fr",
            .spanish: "es",
            .italian: "it",
            .german: "de",
            .turkish: "tr",
            .russian: "ru",
            .portuguese: "pt",
            .vietnamese: "vi",
            .indonesian: "id",
            .thai: "th",
            .malay: "ms",
            .arabic: "ar",
            .hindi: "hi",
        ]
        dic.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        NSLog("Tencent Translate currently does not support OCR")
        throw QueryServiceError.notSupported
    }

//MARK: API Request
    private var apiEndPoint = "https://tmt.tencentcloudapi.com"

    private static let defaultTestToken = ""

    private var token: String {
        let token = UserDefaults.standard.string(forKey: EZTencentAPIKey)
        if let token, !token.isEmpty {
            return token
        } else {
            return TencentService.defaultTestToken
        }
    }

    public override func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        if prehandleQueryTextLanguage(text, autoConvertChineseText: false, from: from, to: to, completion: completion) {
            return
        }
        let transType = TencentTranslateType.type(from: from, to: to)
        guard transType != .unsupported else {
            result.errorType = .unsupportedLanguage
            result.errorMessage = "不支持的翻译类型: \(from.rawValue) --> \(to.rawValue)"
            completion(result, nil)
            return
        }

        let parameters: [String: Any] = [
            "SourceText": text.split(separator: "\n"),
            "Source": transType.sourceLanguage,
            "Target": transType.targetLanguage,
            "ProjectId": "0",
        ]

//MARK: Header Reqest
        let timeStamp = String(Int(Date().timeIntervalSince1970))

        let headers: HTTPHeaders = [
            "Authorization": "",
            "Content-Type": "application/json",
            "Host": "tmt.tencentcloudapi.com",
            "X-TC-Action": "TextTranslate",
            "X-TC-Timestamp": timeStamp,
            "X-TC-Version": "2018-03-21",
            "X-TC-Region": "ap-guangzhou",
            "X-TC-Token": "",
        ]


        let request = AF.request(apiEndPoint,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers)

            .validate()
            .responseDecodable(of: TencentResponse.self) { [weak self] response in
                guard let self else { return }
                let result = self.result
                switch response.result {
                case let .success(value):
                    result.from = from
                    result.to = to
                    result.queryText = text
                    result.translatedResults = value.TargetText
                    completion(result, nil)
                case let .failure(error):
                    NSLog("Tencent lookup error \(error)")
                    completion(result, error)
                }
            }
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
