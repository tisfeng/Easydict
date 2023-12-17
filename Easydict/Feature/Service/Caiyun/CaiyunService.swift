//
//  CaiyunService.swift
//  Easydict
//
//  Created by Kyle on 2023/11/7.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import Foundation

@objc(EZCaiyunService)
public final class CaiyunService: QueryService {
    override public func serviceType() -> ServiceType {
        .caiyun
    }

    override public func link() -> String? {
        "https://fanyi.caiyunapp.com"
    }

    override public func name() -> String {
        NSLocalizedString("caiyun_translate", comment: "The name of Caiyun Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary.
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        CaiyunTranslateType.supportLanguagesDictionary.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        NSLog("Caiyun Translate does not support OCR")
        throw QueryServiceError.notSupported
    }

    private var apiEndPoint = "https://api.interpreter.caiyunai.com/v1/translator"

    /// Official Test Token for Caiyun
    private static let defaultTestToken = "5VZ61ZCRzQ2uTbp6MPaUGdoqXGklkB3WifIBPamAwLc=".decryptAES()

    // easydict://writeKeyValue?EZCaiyunToken=
    private var token: String {
        let token = UserDefaults.standard.string(forKey: EZCaiyunToken)
        if let token, !token.isEmpty {
            return token
        } else {
            return CaiyunService.defaultTestToken
        }
    }

    override public func autoConvertTraditionalChinese() -> Bool {
        true
    }

    override public func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        let transType = CaiyunTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, description: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        // Docs: https://docs.caiyunapp.com/blog/
        let parameters: [String: Any] = [
            "source": text.split(separator: "\n", omittingEmptySubsequences: false),
            "trans_type": transType.rawValue,
            "media": "text",
            "request_id": "Easydict",
            "detect": true,
        ]
        let headers: HTTPHeaders = [
            "content-type": "application/json",
            "x-authorization": "token " + token,
        ]

        let request = AF.request(apiEndPoint,
                                 method: .post,
                                 parameters: parameters,
                                 encoding: JSONEncoding.default,
                                 headers: headers)
            .validate()
            .responseDecodable(of: CaiyunResponse.self) { [weak self] response in
                guard let self else { return }
                let result = self.result

                switch response.result {
                case let .success(value):
                    result.from = from
                    result.to = to
                    result.queryText = text
                    result.translatedResults = value.target
                    completion(result, nil)
                case let .failure(error):
                    NSLog("Caiyun lookup error \(error)")
                    let ezError = EZError(nsError: error, errorResponseData: response.data)
                    completion(result, ezError)
                }
            }
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}

enum QueryServiceError: Error {
    case notSupported
}
