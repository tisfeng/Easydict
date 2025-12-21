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
import SwiftUI

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

    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        TencentTranslateType.supportLanguagesDictionary.toMMOrderedDictionary()
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

    /// Returns configuration items for the Tencent service settings view.
    public override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.tencentSecretId, .tencentSecretKey]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_id.title",
                key: .tencentSecretId
            )
            SecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_key.title",
                key: .tencentSecretKey
            )
        }
    }

    /// Translate text using the Tencent API.
    override public func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let transType = TencentTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            throw QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
        }

        // Use `Parameters` type alias, not `[String: Any]`
        // SeeAlso: https://github.com/Alamofire/Alamofire/issues/3983
        let parameters: Parameters = [
            "SourceText": text,
            "Source": transType.sourceLanguage,
            "Target": transType.targetLanguage,
            "ProjectId": 0,
        ]

        // Tencent docs: https://cloud.tencent.com/document/product/551/15619
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

        let currentResult = result ?? QueryResult()
        if result == nil {
            result = currentResult
        }

        let request = AF.request(
            endpoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)

        let dataTask = request
            .validate()
            .serializingDecodable(TencentResponse.self)

        do {
            let value = try await dataTask.value
            currentResult.translatedResults = value.Response.TargetText.components(separatedBy: "\n")
            return currentResult
        } catch {
            logError("Tencent lookup error \(error)")

            if let queryError = error as? QueryError {
                throw queryError
            }

            var queryError = QueryError(type: .api, message: error.localizedDescription)
            let response = await dataTask.response

            if let data = response.data {
                do {
                    let errorResponse = try JSONDecoder().decode(
                        TencentErrorResponse.self, from: data
                    )
                    queryError.errorDataMessage = errorResponse.response.error.message
                } catch {
                    logError("Failed to decode error response: \(error)")
                }
            }

            throw queryError
        }
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
