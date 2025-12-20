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
import SwiftUI

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

    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        CaiyunTranslateType.supportLanguagesDictionary.toMMOrderedDictionary()
    }

    public override func hasPrivateAPIKey() -> Bool {
        token != caiyunToken
    }

    /// Returns configuration items for the Caiyun service settings view.
    public override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.caiyunToken]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.caiyun.token.title",
                key: .caiyunToken
            )
        }
    }

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, Error?) -> ()
    ) {
        let transType = CaiyunTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        // Docs: https://docs.caiyunapp.com/lingocloud-api/
        let parameters: Parameters = [
            "source": text.split(separator: "\n", omittingEmptySubsequences: false),
            "trans_type": transType.rawValue,
            "media": "text",
            "request_id": "Easydict",
            "detect": transType.rawValue.hasPrefix("auto"),
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
            guard let self, let result = result else { return }

            switch response.result {
            case let .success(value):
                result.translatedResults = value.target
                completion(result, nil)
            case let .failure(error):
                logError("Caiyun lookup error \(error)")
                let queryError = QueryError(type: .api, message: error.localizedDescription)
                if let data = response.data {
                    if let errorString = String(data: data, encoding: .utf8) {
                        queryError.errorDataMessage = errorString
                    }
                }
                completion(result, queryError)
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
