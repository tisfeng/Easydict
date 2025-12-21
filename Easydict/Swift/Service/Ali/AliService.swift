//
//  AliService.swift
//  Easydict
//
//  Created by choykarl on 2023/12/20.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import Defaults
import Foundation
import SwiftUI

@objc(EZAliService)
class AliService: QueryService {
    // MARK: Public

    public override func link() -> String? {
        "https://translate.alibaba.com/"
    }

    public override func serviceType() -> ServiceType {
        .alibaba
    }

    public override func name() -> String {
        NSLocalizedString("ali_translate", comment: "The name of Ali Translate")
    }

    public override func hasPrivateAPIKey() -> Bool {
        !aliAccessKeyId.isEmpty && !aliAccessKeySecret.isEmpty
    }

    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        AliTranslateType.supportLanguagesDictionary.toMMOrderedDictionary()
    }

    public override func autoConvertTraditionalChinese() -> Bool {
        // If translate traditionalChinese <--> simplifiedChinese, use Ali API directly.
        if EZLanguageManager.shared().onlyContainsChineseLanguages([
            queryModel.queryFromLanguage,
            queryModel.queryTargetLanguage,
        ]) {
            return false
        }
        return true
    }

    /// Translate text using the Aliyun API.
    override public func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let limit = 5000
        let text = String(text.prefix(limit))

        let transType = AliTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            throw QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
        }

        return try await withCheckedThrowingContinuation { continuation in
            requestByAPI(
                id: aliAccessKeyId,
                secret: aliAccessKeySecret,
                transType: transType,
                text: text,
                from: from,
                to: to
            ) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    // MARK: Internal

    /// Returns configuration items for the Ali service settings view.
    override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.aliAccessKeyId, .aliAccessKeySecret]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_id.title",
                key: .aliAccessKeyId
            )
            SecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_secret.title",
                key: .aliAccessKeySecret
            )
        }
    }

    func hmacSha1(key: String, params: String) -> String? {
        guard let secret = key.data(using: .utf8),
              let what = params.data(using: .utf8)
        else {
            return nil
        }
        var hmac = HMAC<Insecure.SHA1>(key: SymmetricKey(data: secret))
        hmac.update(data: what)
        let mac = Data(hmac.finalize())
        return mac.base64EncodedString()
    }

    // MARK: Private

    private let dateFormatter = ISO8601DateFormatter()

    private var aliAccessKeyId: String {
        Defaults[.aliAccessKeyId]
    }

    private var aliAccessKeySecret: String {
        Defaults[.aliAccessKeySecret]
    }

    // swiftlint:disable:next function_parameter_count
    private func requestByAPI(
        id: String,
        secret: String,
        transType: AliTranslateType,
        text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, Error?) -> ()
    ) {
        if id.isEmpty || secret.isEmpty {
            let message = String(localized: "service.configuration.api_missing.tips \(name())")
            completion(result, QueryError(type: .missingSecretKey, message: message))
            return
        }

        /// https://help.aliyun.com/zh/sdk/product-overview/rpc-mechanism?spm=a2c4g.11186623.0.i20#sectiondiv-6jf-89b-wfa
        var param = [
            "FormatType": "text",
            "SourceLanguage": transType.sourceLanguage,
            "TargetLanguage": transType.targetLanguage,
            "SourceText": text,
            "Scene": "general",

            /// common
            "Action": "TranslateGeneral",
            "Version": "2018-10-12",
            "Format": "JSON",
            "AccessKeyId": id,
            "SignatureNonce": UUID().uuidString,
            "Timestamp": dateFormatter.string(from: Date()),
            "SignatureMethod": "HMAC-SHA1",
            "SignatureVersion": "1.0",
        ]

        let allowedCharacterSet =
            CharacterSet(
                charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
            )

        let sortParams = param.keys.sorted()

        var paramsEncodeErrorString = ""
        let canonicalizedQueryString = sortParams.map { key in
            guard let keyEncode = key.addingPercentEncoding(
                withAllowedCharacters: allowedCharacterSet
            ),
                let valueEncode = param[key]?.addingPercentEncoding(
                    withAllowedCharacters: allowedCharacterSet
                )
            else {
                paramsEncodeErrorString = paramsEncodeErrorString + "\(key) param encoding error \n"
                return ""
            }
            return "\(keyEncode)=\(valueEncode)"
        }.joined(separator: "&")

        if !paramsEncodeErrorString.isEmpty {
            completion(result, QueryError(type: .parameter, message: paramsEncodeErrorString))
            return
        }

        guard let slashEncode = "/".addingPercentEncoding(withAllowedCharacters: allowedCharacterSet),
              let canonicalizedQueryStringEncode =
              canonicalizedQueryString
                  .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        else {
            completion(result, QueryError(type: .parameter, message: "encoding error"))
            return
        }

        let stringToSign = "POST" + "&" + slashEncode + "&" + canonicalizedQueryStringEncode

        guard let signData = stringToSign.data(using: .utf8),
              let utf8String = String(
                  data: signData,
                  encoding: .nonLossyASCII
              )
        else {
            completion(result, QueryError(type: .parameter, message: "signature error"))
            return
        }

        guard let signature = hmacSha1(key: secret + "&", params: utf8String) else {
            completion(result, QueryError(type: .parameter, message: "hmacSha1 error"))
            return
        }

        param["Signature"] = signature

        let currentResult = result ?? QueryResult()
        if result == nil {
            result = currentResult
        }

        let request = AF.request("https://mt.aliyuncs.com", method: .post, parameters: param)
            .validate()
            .responseDecodable(of: AliAPIResponse.self) { [weak self] response in
                guard let self else {
                    completion(
                        currentResult,
                        QueryError.error(
                            type: .unknown,
                            message: "Service released before completing the request"
                        )
                    )
                    return
                }

                switch response.result {
                case let .success(value):
                    if let data = value.data, let translateText = data.translated {
                        currentResult.translatedResults = [translateText]
                        completion(currentResult, nil)
                    } else {
                        completion(
                            currentResult,
                            QueryError(type: .api, message: value.code?.stringValue, errorDataMessage: value.message)
                        )
                    }
                case let .failure(error):
                    var msg: String?
                    if let data = response.data {
                        let res = try? JSONDecoder().decode(AliAPIResponse.self, from: data)
                        msg = res?.message
                    }

                    logError("Ali translate error: \(msg ?? "")")
                    completion(
                        currentResult,
                        QueryError(type: .api, message: error.localizedDescription, errorDataMessage: msg)
                    )
                }
            }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
