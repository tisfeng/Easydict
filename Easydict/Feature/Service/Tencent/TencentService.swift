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
        TencentTranslateType.supportLanguagesDictionary.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        NSLog("Tencent Translate currently does not support OCR")
        throw QueryServiceError.notSupported
    }

    // MARK: API Request
    private static let defaultSecretId = ""
    private static let defaultSecretKey = ""


    // easydict://writeKeyValue?EZTencentSecretId=xxx
    private var secretId: String {
        let secretId = UserDefaults.standard.string(forKey: EZTencentSecretId)
        if let secretId, !secretId.isEmpty {
            return secretId
        } else {
            return TencentService.defaultSecretId
        }
    }

    // easydict://writeKeyValue?EZTencentSecretKey=xxx
    private var secretKey: String {
        let secretKey = UserDefaults.standard.string(forKey: EZTencentSecretKey)
        if let secretKey, !secretKey.isEmpty {
            return secretKey
        } else {
            return TencentService.defaultSecretKey
        }
    }

    public override func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        if prehandleQueryTextLanguage(text, from: from, to: to, completion: completion) {
            return
        }

        translateText(text, from: from, to: to, completion: completion)
    }

    func translateText(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        let transType = TencentTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            result.errorType = .unsupportedLanguage
            let unsupportedType = NSLocalizedString("unsupported_translation_type", comment: "")
            result.errorMessage = "\(unsupportedType): \(from.rawValue) --> \(to.rawValue)"
            completion(result, nil)
            return
        }

        let parameters: [String: Any] = [
            "SourceText": text,
            "Source": transType.sourceLanguage,
            "Target": transType.targetLanguage,
            "ProjectId": 0
        ]

        let endpoint = "https://tmt.tencentcloudapi.com"

        let service = "tmt"
        let action = "TextTranslate"
        let version = "2018-03-21"

        let headers = tencentSignHeader(service: service, action: action, version: version, parameters: parameters, secretId: secretId, secretKey: secretKey)

        let request = AF.request(endpoint,
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
                    result.translatedResults = value.Response.TargetText.components(separatedBy: "\n")
                    completion(result, nil)
                case let .failure(error):
                    NSLog("Tencent lookup error \(error)")
                    if let data = response.data {
                        do {
                            let errorResponse = try JSONDecoder().decode(TencentErrorResponse.self, from: data)
                            result.errorMessage = errorResponse.response.error.message
                        } catch {
                            NSLog("Failed to decode error response: \(error)")
                        }
                    }
                    completion(result, error)
                }
            }
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
