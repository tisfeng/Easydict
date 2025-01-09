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

    public override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
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

    // MARK: Internal

    private(set) var tokenResponse: AliTokenResponse?
    private(set) var canWebRetry = true

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let limit = 5000
        let text = String(text.prefix(limit))

        let transType = AliTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        if Defaults[.aliServiceApiTypeKey] == .secretKey {
            requestByAPI(
                id: aliAccessKeyId,
                secret: aliAccessKeySecret,
                transType: transType,
                text: text,
                from: from,
                to: to,
                completion: completion
            )
        } else { // use web api
            if hasToken.has {
                requestByWeb(transType: transType, text: text, from: from, to: to, completion: completion)
                return
            }

            // get web request token
            let request = AF.request("https://translate.alibaba.com/api/translate/csrftoken", method: .get)
                .validate()
                .responseDecodable(of: AliTokenResponse.self) { [weak self] response in
                    guard let self else { return }
                    switch response.result {
                    case let .success(value):
                        tokenResponse = value
                    case let .failure(error):
                        logError("ali translate get token error: \(error)")
                    }

                    requestByWeb(transType: transType, text: text, from: from, to: to, completion: completion)
                }

            queryModel.setStop({
                request.cancel()
            }, serviceType: serviceType().rawValue)
        }
    }

    // MARK: Private

    private let dateFormatter = ISO8601DateFormatter()

    private var hasToken: (has: Bool, token: String, parameterName: String) {
        if let token = tokenResponse?.token, let parameterName = tokenResponse?.parameterName, !token.isEmpty,
           !parameterName.isEmpty {
            (true, token, parameterName)
        } else {
            (false, "", "")
        }
    }

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
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        if id.isEmpty || secret.isEmpty {
            completion(
                result,
                EZError(
                    type: EZErrorType.missingAPIKey,
                    message: String.localizedStringWithFormat(
                        NSLocalizedString("service.configuration.api_missing.tips %@", comment: "API key missing"),
                        name()
                    )
                )
            )
            return
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
            CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")

        let sortParams = param.keys.sorted()

        var paramsEncodeErrorString = ""
        let canonicalizedQueryString = sortParams.map { key in
            guard let keyEncode = key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet),
                  let valueEncode = param[key]?.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
            else {
                paramsEncodeErrorString = paramsEncodeErrorString + "\(key) param encoding error \n"
                return ""
            }
            return "\(keyEncode)=\(valueEncode)"
        }.joined(separator: "&")

        if !paramsEncodeErrorString.isEmpty {
            completion(result, EZError(type: .API, message: paramsEncodeErrorString))
            return
        }

        guard let slashEncode = "/".addingPercentEncoding(withAllowedCharacters: allowedCharacterSet),
              let canonicalizedQueryStringEncode = canonicalizedQueryString
              .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        else {
            completion(result, EZError(type: .API, message: "encoding error"))
            return
        }

        let stringToSign = "POST" + "&" + slashEncode + "&" + canonicalizedQueryStringEncode

        guard let signData = stringToSign.data(using: .utf8), let utf8String = String(
            data: signData,
            encoding: .nonLossyASCII
        ) else {
            completion(result, EZError(type: .API, message: "signature error"))
            return
        }

        guard let signature = hmacSha1(key: secret + "&", params: utf8String) else {
            completion(result, EZError(type: .API, message: "hmacSha1 error"))
            return
        }

        param["Signature"] = signature

        let request = AF.request("https://mt.aliyuncs.com", method: .post, parameters: param)
            .validate()
            .responseDecodable(of: AliAPIResponse.self) { [weak self] response in
                guard let self else { return }
                let result = result

                switch response.result {
                case let .success(value):
                    if let data = value.data, let translateText = data.translated {
                        result.translatedResults = [translateText]
                        completion(result, nil)
                    } else {
                        completion(
                            result,
                            EZError(type: .API, message: value.code?.stringValue, errorDataMessage: value.message)
                        )
                    }
                case let .failure(error):
                    var msg: String?
                    if let data = response.data {
                        let res = try? JSONDecoder().decode(AliAPIResponse.self, from: data)
                        msg = res?.message
                    } else {
                        msg = error.errorDescription
                    }

                    logError("Ali translate error: \(msg ?? "")")
                    completion(result, EZError(nsError: error, errorDataMessage: msg))
                }
            }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }

    /// If there is a token, use the POST method and request with the token as a parameter; otherwise, use the GET method to request.
    private func requestByWeb(
        transType: AliTranslateType,
        text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
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

        let request = AF.request(
            "https://translate.alibaba.com/api/translate/text",
            method: hasToken.has ? .post : .get,
            parameters: parameters
        )
        .validate()
        .responseDecodable(of: AliWebResponse.self) { [weak self] response in
            guard let self else { return }
            let result = result

            switch response.result {
            case let .success(value):
                if value.success, let translateText = value.data?.translateText {
                    result.translatedResults = [translateText.unescapedXML()]
                    completion(result, nil)
                    logInfo("ali web translate success")
                } else {
                    let ezError = EZError(
                        type: .API,
                        message: value.code?.stringValue,
                        errorDataMessage: value.message
                    )
                    completion(result, ezError)
                }
                canWebRetry = true
            case let .failure(error):
                // The result returned when the token expires is HTML.
                if hasToken.has, error.isResponseSerializationError {
                    logError("ali web token invaild")
                    tokenResponse = nil
                    if canWebRetry {
                        canWebRetry = false
                        // Request token again.
                        translate(text, from: from, to: to, completion: completion)
                    } else {
                        requestByWeb(transType: transType, text: text, from: from, to: to, completion: completion)
                    }

                } else {
                    var msg: String?
                    if let data = response.data {
                        let res = try? JSONDecoder().decode(AliWebResponse.self, from: data)
                        msg = res?.message
                    } else {
                        msg = error.errorDescription
                    }

                    logError("ali web translate error: \(msg ?? "")")
                    completion(result, EZError(nsError: error, errorDataMessage: msg))
                }
            }
        }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
