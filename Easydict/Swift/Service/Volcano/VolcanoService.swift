//
//  VolcanoService.swift
//  Easydict
//
//  Created by Jerry on 2024-08-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

@objc(EZVolcanoService)
public final class VolcanoService: QueryService {
    // MARK: Public

    override public func serviceType() -> ServiceType {
        .volcano
    }

    override public func link() -> String? {
        "https://translate.volcengine.com"
    }

    override public func wordLink(_ queryModel: EZQueryModel) -> String? {
        guard let from = languageCode(forLanguage: queryModel.queryFromLanguage),
              let to = languageCode(forLanguage: queryModel.queryTargetLanguage),
              let queryText = queryModel.queryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        return "https://translate.volcengine.com/?source_language=\(from)&target_language=\(to)&text=\(queryText)"
    }

    override public func name() -> String {
        NSLocalizedString("volcano_translate", comment: "The name of Volcano Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for (key, value) in VolcanoTranslateType.supportLanguagesDictionary {
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let result = result
        if let error = validateAPIKey(accessKeyID, keyType: "AccessKeyID") {
            completion(result, error)
            return
        }

        if let error = validateAPIKey(secretAccessKey, keyType: "SecretAccessKey") {
            completion(result, error)
            return
        }

        let transType = VolcanoTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, description: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        let parameters: [String: Any] = [
            "SourceLanguage": transType.sourceLanguage,
            "TargetLanguage": transType.targetLanguage,
            "TextList": [text],
        ]

        let host = "https://translate.volcengineapi.com"
        let uri = "/"
        let queryString = "Action=TranslateText&Version=2020-06-01"
        let region = "cn-north-1"
        let service = "translate"

        let headers = volcanoSigning(
            accessKeyId: accessKeyID,
            secretAccessKey: secretAccessKey,
            host: host,
            uri: uri,
            queryString: queryString,
            region: region,
            service: service,
            parameters: parameters
        )

        let afHost = host + uri + "?" + queryString

        let request = AF.request(
            afHost,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: VolcanoResponse.self) { [weak self] response in
            guard self != nil else { return }

            switch response.result {
            case let .success(volcanoResponse):
                if let error = volcanoResponse.responseMetadata.error {
                    let errorMessage = error.message
                    logError("Volcano lookup error: \(errorMessage)")
                    let ezError = EZError(type: .API, description: errorMessage)
                    completion(result, ezError)
                } else if let translationList = volcanoResponse.translationList {
                    result.translatedResults = translationList.map { $0.translation }
                    completion(result, nil)
                } else {
                    let errorMessage = "Unexpected response format"
                    logError("Volcano lookup error: \(errorMessage)")
                    let ezError = EZError(type: .none, description: errorMessage)
                    completion(result, ezError)
                }

            case let .failure(error):
                logError("Volcano lookup error: \(error)")
                let ezError = EZError(nsError: error)

                if let data = response.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(VolcanoResponse.self, from: data)
                        if let volcanoError = errorResponse.responseMetadata.error {
                            ezError?.errorDataMessage = volcanoError.message
                        }
                    } catch {
                        logError("Failed to decode error response: \(error)")
                    }
                }
                completion(result, ezError)
            }
        }
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }

    // MARK: Private

    // easydict://writeKeyValue?EZVolcanoAccessKeyID=xxx
    private var accessKeyID: String {
        Defaults[.volcanoAccessKeyID]
    }

    // easydict://writeKeyValue?EZVolcanoSecretAccessKey=xxx
    private var secretAccessKey: String {
        Defaults[.volcanoSecretAccessKey]
    }

    /// Validates the provided API key, returns an EZError of type `.missingAPIKey`
    /// with a description indicating a missing Volcano `keyType` and instructions
    /// to get one if `key` is empty,  returns nil otherwise
    private func validateAPIKey(_ key: String, keyType: String) -> EZError? {
        if key.isEmpty {
            return EZError(
                type: .missingAPIKey,
                description: "Missing Volcano \(keyType). Volcano Service requires users' own API Key. Get it at https://www.volcengine.com"
            )
        }
        return nil
    }
}
