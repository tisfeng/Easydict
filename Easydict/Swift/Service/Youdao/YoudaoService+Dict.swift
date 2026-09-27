//
//  YoudaoService+Dict.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Foundation

extension YoudaoService {
    func queryYoudaoDict(text: String, from: Language, to: Language) async throws -> QueryResult {
        try await queryDictionaryV4(text: text, from: from, to: to)
    }

    // MARK: - Youdao Web Dictionary API V4 (Updated at 2025/01/03)

    func queryDictionaryV4(text: String, from: Language, to: Language) async throws -> QueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        guard supportedQueryType().contains(.dictionary) else {
            throw QueryError(type: .unsupportedQueryType)
        }

        guard let foreignLanguage = youdaoDictForeignLanguage(queryModel) else {
            throw QueryError(type: .unsupportedLanguage)
        }

        let ww = "\(text)webdict"
        let time = ww.count % 10
        let salt = ww.md5()
        let key = "Mk6hqtUp33DGGtoS63tTJbMUYjRrG1Lu"
        let sign = "web\(text)\(time)\(key)\(salt)".md5()

        let parameters = [
            "q": text,
            "le": foreignLanguage,
            "client": "web",
            "t": time,
            "sign": sign,
            "keyfrom": "webdict",
        ] as [String: Any]

        let url = "\(kYoudaoDictURL)/jsonapi_s?doctype=json&jsonversion=4"

        do {
            // Get the raw data
            let responseData = try await AF.request(
                url,
                method: .post,
                parameters: parameters
            )
            .serializingData()
            .value

            // Decode the data
            let response = try JSONDecoder().decode(YoudaoDictResponseV4.self, from: responseData)
            result.update(dictV4: response)
            return result
        } catch {
            throw QueryError(
                type: .api,
                message: "Failed to query Youdao dictionary: \(error)"
            )
        }
    }

    func youdaoDictForeignLanguage(_ queryModel: QueryModel) -> String? {
        let fromLanguage = queryModel.queryFromLanguage
        let toLanguage = queryModel.queryTargetLanguage

        let supportedLanguages: [Language] = [.english, .japanese, .french, .korean]

        var foreignLanguage: String?

        if fromLanguage.isChinese {
            foreignLanguage = languageCode(forLanguage: toLanguage)
        } else if toLanguage.isChinese {
            foreignLanguage = languageCode(forLanguage: fromLanguage)
        }

        let supportedCodes = supportedLanguages.map { languageCode(forLanguage: $0) }
        return supportedCodes.contains(foreignLanguage ?? "") ? foreignLanguage : nil
    }
}
