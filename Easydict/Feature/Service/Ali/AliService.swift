//
//  AliService.swift
//  Easydict
//
//  Created by choykarl on 2023/12/20.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import Foundation

@objc(EZAliService)
class AliService: QueryService {
    private(set) var tokenResponse: AliTokenResponse?
    private(set) var canRetry = true

    var hasToken: (has: Bool, token: String, parameterName: String) {
        if let token = tokenResponse?.token, let parameterName = tokenResponse?.parameterName, !token.isEmpty, !parameterName.isEmpty {
            return (true, token, parameterName)
        } else {
            return (false, "", "")
        }
    }

    override func serviceType() -> ServiceType {
        .ali
    }

    override public func link() -> String? {
        "https://translate.alibaba.com/"
    }

    override public func name() -> String {
        NSLocalizedString("ali_translate", comment: "The name of Ali Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary in the API
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        AliTranslateType.supportLanguagesDictionary.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        print("ali Translate does not support OCR")
        throw QueryServiceError.notSupported
    }

    override public func autoConvertTraditionalChinese() -> Bool {
        // If translate traditionalChinese <--> simplifiedChinese, use Ali API directly.
        if EZLanguageManager.shared().onlyContainsChineseLanguages([queryModel.queryFromLanguage, queryModel.queryTargetLanguage]) {
            return false
        }
        return true
    }

    override func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        let transType = AliTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, description: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        if hasToken.has {
            self.request(transType: transType, text: text, from: from, to: to, completion: completion)
            return
        }

        // get request token
        let request = AF.request("https://translate.alibaba.com/api/translate/csrftoken", method: .get)
            .validate()
            .responseDecodable(of: AliTokenResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case let .success(value):
                    tokenResponse = value
                case let .failure(error):
                    print("ali translate get token error: \(error)")
                }

                self.request(transType: transType, text: text, from: from, to: to, completion: completion)
            }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }

    /// If there is a token, use the POST method and request with the token as a parameter; otherwise, use the GET method to request.
    private func request(transType: AliTranslateType, text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        var parameters = [
            "srcLang": transType.sourceLanguage,
            "tgtLang": transType.targetLanguage,
            "domain": "general",
            "query": text,
        ]

        let hasToken = hasToken
        if hasToken.has {
            parameters[hasToken.parameterName] = hasToken.token
        }

        let request = AF.request("https://translate.alibaba.com/api/translate/text",
                                 method: hasToken.has ? .post : .get,
                                 parameters: parameters)
            .validate()
            .responseDecodable(of: AliResponse.self) { [weak self] response in
                guard let self else { return }
                let result = self.result

                switch response.result {
                case let .success(value):
                    result.from = from
                    result.to = to
                    result.queryText = text
                    if let data = value.data, let translateText = data.translateText {
                        result.translatedResults = [translateText.unescapedXML()]
                        completion(result, nil)
                    } else {
                        let ezError = EZError(type: .API, description: value.code, errorDataMessage: value.message)
                        completion(result, ezError)
                    }
                    canRetry = true
                case let .failure(error):
                    // The result returned when the token expires is HTML.
                    if hasToken.has, error.isResponseSerializationError {
                        print("ali token invaild")
                        tokenResponse = nil
                        if canRetry {
                            canRetry = false
                            // Request token again.
                            translate(text, from: from, to: to, completion: completion)
                        } else {
                            self.request(transType: transType, text: text, from: from, to: to, completion: completion)
                        }

                    } else {
                        print("ali lookup error \(error)")
                        let ezError = EZError(nsError: error, errorResponseData: response.data)
                        completion(result, ezError)
                    }
                }
            }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
