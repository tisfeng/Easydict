//
//  CaiyunService.swift
//  Easydict
//
//  Created by Kyle on 2023/11/7.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

// MARK: - CaiyunService

@objc(EZCaiyunService)
public final class CaiyunService: QueryService {
    // MARK: Public

    public override func serviceType() -> ServiceType {
        .caiyun
    }

    public override func link() -> String? {
        "https://fanyi.caiyunapp.com"
    }

    public override func name() -> String {
        NSLocalizedString("caiyun_translate", comment: "The name of Caiyun Translate")
    }

    public override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary.
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for (key, value) in CaiyunTranslateType.supportLanguagesDictionary {
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    public override func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        logInfo("Caiyun Translate does not support OCR")
        throw QueryServiceError.notSupported
    }

    public override func hasPrivateAPIKey() -> Bool {
        token != caiyunToken
    }

    public override func autoConvertTraditionalChinese() -> Bool {
        true
    }

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let transType = CaiyunTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, description: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        // Docs: https://docs.caiyunapp.com/lingocloud-api/
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

        let request = AF.request(
            apiEndPoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: CaiyunResponse.self) { [weak self] response in
            guard let self else { return }
            let result = result

            switch response.result {
            case let .success(value):
                result.translatedResults = value.target
                completion(result, nil)
            case let .failure(error):
                logError("Caiyun lookup error \(error)")
                let ezError = EZError(nsError: error, errorResponseData: response.data)
                completion(result, ezError)
            }
        }
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }

    // MARK: Private

    private var apiEndPoint = "https://api.interpreter.caiyunai.com/v1/translator"

    // easydict://writeKeyValue?EZCaiyunToken=
    private var token: String {
        let token = Defaults[.caiyunToken]
        if !token.isEmpty {
            return token
        } else {
            return caiyunToken
        }
    }
}

// MARK: - QueryServiceError

enum QueryServiceError: Error {
    case notSupported
}
