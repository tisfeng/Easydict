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

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        logInfo("Volcano Translate currently does not support OCR")
        throw QueryServiceError.notSupported
    }

    override public func needPrivateAPIKey() -> Bool {
        true
    }

    override public func hasPrivateAPIKey() -> Bool {
        if accessKeyID.isEmpty, secretAccessKey.isEmpty {
            return false
        }
        return true
    }

    // https://www.volcengine.com/docs/4640/68515
    override public func totalFreeQueryCharacterCount() -> Int {
        200 * 10000
    }

    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        // swiftlint:disable line_length
        guard !accessKeyID.isEmpty else {
            let noAccessKeyIDError = EZError(
                type: .missingAPIKey,
                description: "Missing Volcano AccessKeyID. Volcano Service requires users' own API Key. Get it at https://www.volcengine.com"
            )
            completion(result, noAccessKeyIDError)
            return
        }
        guard !secretAccessKey.isEmpty else {
            let noSecretAccessKey = EZError(
                type: .missingAPIKey,
                description: "Missing Volcano SecretAccessKey. Volcano Service requires users' own API Key. Get it at https://www.volcengine.com"
            )
            completion(result, noSecretAccessKey)
            return
        }
        // swiftlint:enable line_length
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
            let result = EZQueryResult()

            switch response.result {
            case let .success(volcanoResponse):
                if volcanoResponse.error == nil {
                    result.from = from
                    result.to = to
                    result.queryText = text

                    if let translationList = volcanoResponse.translationList {
                        result.translatedResults = translationList.map { $0.translation }
                    }

                    completion(result, nil)
                } else {
                    let errorMessage = volcanoResponse.error?.message ?? "Unknown error occurred"
                    logError("Volcano lookup error: \(errorMessage)")
                    let ezError = EZError(nsError: errorMessage as? Error)
                    completion(result, ezError)
                }

            case let .failure(error):
                logError("Volcano lookup error: \(error)")
                let ezError = EZError(nsError: error)

                if let data = response.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(VolcanoResponse.self, from: data)
                        ezError?.errorDataMessage = errorResponse.error?.message
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
    private var accessKeyID = Defaults[.volcanoAccessKeyID]

    // easydict://writeKeyValue?EZVolcanoSecretAccessKey=xxx
    private var secretAccessKey = Defaults[.volcanoSecretAccessKey]
}
