//
//  TencentService.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

@objc(EZTencentService)
public final class TencentService: QueryService {
    // MARK: Public

    public override func serviceType() -> ServiceType {
        .tencent
    }

    public override func link() -> String? {
        "https://fanyi.qq.com"
    }

    public override func name() -> String {
        NSLocalizedString("tencent_translate", comment: "The name of Tencent Translate")
    }

    public override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        for (key, value) in TencentTranslateType.supportLanguagesDictionary {
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    public override func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        logInfo("Tencent Translate currently does not support OCR")
        throw QueryServiceError.notSupported
    }

    public override func needPrivateAPIKey() -> Bool {
        true
    }

    public override func hasPrivateAPIKey() -> Bool {
        if secretId == tencentSecretId, secretKey == tencentSecretKey {
            return false
        }
        return true
    }

    public override func totalFreeQueryCharacterCount() -> Int {
        500 * 10000
    }

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let transType = TencentTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, description: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        let parameters: [String: Any] = [
            "SourceText": text,
            "Source": transType.sourceLanguage,
            "Target": transType.targetLanguage,
            "ProjectId": 0,
        ]

        let endpoint = "https://tmt.tencentcloudapi.com"

        let service = "tmt"
        let action = "TextTranslate"
        let version = "2018-03-21"

        let headers = tencentSignHeader(
            service: service,
            action: action,
            version: version,
            parameters: parameters,
            secretId: secretId,
            secretKey: secretKey
        )

        let request = AF.request(
            endpoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: TencentResponse.self) { [weak self] response in
            guard let self else { return }
            let result = result

            switch response.result {
            case let .success(value):
                result.from = from
                result.to = to
                result.queryText = text
                result.translatedResults = value.Response.TargetText.components(separatedBy: "\n")
                completion(result, nil)
            case let .failure(error):
                logError("Tencent lookup error \(error)")
                let ezError = EZError(nsError: error)

                if let data = response.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(TencentErrorResponse.self, from: data)
                        ezError?.errorDataMessage = errorResponse.response.error.message
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

    // easydict://writeKeyValue?EZTencentSecretId=xxx
    private var secretId: String {
        let secretId = Defaults[.tencentSecretId]
        if !secretId.isEmpty {
            return secretId
        } else {
            return tencentSecretId
        }
    }

    // easydict://writeKeyValue?EZTencentSecretKey=xxx
    private var secretKey: String {
        let secretKey = Defaults[.tencentSecretKey]
        if !secretKey.isEmpty {
            return secretKey
        } else {
            return tencentSecretKey
        }
    }
}
