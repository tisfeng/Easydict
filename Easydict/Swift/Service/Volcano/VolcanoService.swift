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

    override public func wordLink(_ queryModel: QueryModel) -> String? {
        guard let from = languageCode(forLanguage: queryModel.queryFromLanguage),
              let to = languageCode(forLanguage: queryModel.queryTargetLanguage),
              let queryText = queryModel.queryText.addingPercentEncoding(
                  withAllowedCharacters: .urlQueryAllowed
              )
        else {
            return nil
        }

        return
            "https://translate.volcengine.com/?source_language=\(from)&target_language=\(to)&text=\(queryText)"
    }

    override public func name() -> String {
        NSLocalizedString("volcano_translate", comment: "The name of Volcano Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary {
        VolcanoTranslateType.supportLanguagesDictionary.toMMOrderedDictionary()
    }

    public override func hasPrivateAPIKey() -> Bool {
        !accessKeyID.isEmpty && !secretAccessKey.isEmpty
    }

    /// Volcano Translate API: https://www.volcengine.com/docs/4640/65067
    /// Translate text using Volcano API.
    override public func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        guard let result = result else {
            return QueryResult()
        }

        if let error = validateAPIKey(accessKeyID, keyType: "AccessKeyID") {
            throw error
        }

        if let error = validateAPIKey(secretAccessKey, keyType: "SecretAccessKey") {
            throw error
        }

        let transType = VolcanoTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            throw QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
        }

        let parameters: Parameters = [
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

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)

        let dataTask = request
            .validate()
            .serializingDecodable(VolcanoResponse.self)

        do {
            let volcanoResponse = try await dataTask.value

            if let error = volcanoResponse.responseMetadata.error {
                let errorMessage = error.message
                logError("Volcano lookup error: \(errorMessage)")
                throw QueryError(type: .api, message: errorMessage)
            }

            if let translationList = volcanoResponse.translationList {
                result.translatedResults = translationList.map { $0.translation }
                return result
            }

            let errorMessage = "Unexpected response format"
            logError("Volcano lookup error: \(errorMessage)")
            throw QueryError(type: .unknown, message: errorMessage)
        } catch {
            if let queryError = error as? QueryError {
                throw queryError
            }

            logError("Volcano lookup error: \(error)")

            let errorMessage = error.localizedDescription
            let queryError = QueryError(type: .api, message: errorMessage)

            let response = await dataTask.response

            if let data = response.data {
                do {
                    let errorResponse = try JSONDecoder().decode(
                        VolcanoResponse.self, from: data
                    )
                    if let volcanoError = errorResponse.responseMetadata.error {
                        queryError.errorDataMessage = volcanoError.message
                    }
                } catch {
                    logError("Failed to decode error response: \(error)")
                }
            }
            throw queryError
        }
    }

    public override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.volcanoAccessKeyID, .volcanoSecretAccessKey]
        ) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.volcano.access_id.title",
                key: .volcanoAccessKeyID
            )
            SecureInputCell(
                textFieldTitleKey: "service.configuration.volcano.secret_key.title",
                key: .volcanoSecretAccessKey
            )
        }
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

    /// Validates the provided API key, returns a QueryError of type `.missingAPIKey`
    /// with a description indicating a missing Volcano `keyType` and instructions
    /// to get one if `key` is empty,  returns nil otherwise
    private func validateAPIKey(_ key: String, keyType: String) -> QueryError? {
        if key.isEmpty {
            return QueryError(
                type: .missingSecretKey,
                message:
                "Missing Volcano \(keyType). Volcano Service requires users' own API Key. Get it at https://www.volcengine.com"
            )
        }
        return nil
    }
}
