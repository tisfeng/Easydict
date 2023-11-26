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

        // Use the Alamofire module to create and send a POST request to the API endpoint with the parameters and headers
        let request = AF.request(apiEndPoint,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers)
            // Validate the response
            .validate()
            // Decode the response as a CaiyunResponse object
            .responseDecodable(of: TencentResponse.self) { [weak self] response in
                // Use a weak reference to self to avoid memory leaks
                guard let self else { return }
                // Get the result object from self
                let result = self.result
                // Switch on the response result
                switch response.result {
                // If success, assign the value to a constant
                case let .success(value):
                    // Set the from, to, queryText, and translatedResults properties of the result object with the corresponding values
                    result.from = from
                    result.to = to
                    result.queryText = text
                    result.translatedResults = value.TargetText
                    // Call the completion closure with the result object and nil error
                    completion(result, nil)
                // If failure, assign the error to a constant
                case let .failure(error):
                    // Log the error message
                    NSLog("Tencent lookup error \(error)")
                    // Call the completion closure with the result object and the error
                    completion(result, error)
                }
            }
        // Set the stop closure of the queryModel object with a closure that cancels the request
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
