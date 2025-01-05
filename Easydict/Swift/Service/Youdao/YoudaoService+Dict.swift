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
    func queryYoudaoDict(text: String, from: Language, to: Language) async throws -> EZQueryResult {
        try await jsonapi_sApiQuery(text: text, from: from, to: to)
    }

    func youdaoDictForeignLanguage(_ queryModel: EZQueryModel) -> String? {
        let fromLanguage = queryModel.queryFromLanguage
        let toLanguage = queryModel.queryTargetLanguage

        let supportedLanguages: [Language] = [.english, .japanese, .french, .korean]

        var foreignLanguage: String?

        if fromLanguage.isKindOfChinese() {
            foreignLanguage = languageCode(forLanguage: toLanguage)
        } else if toLanguage.isKindOfChinese() {
            foreignLanguage = languageCode(forLanguage: fromLanguage)
        }

        let supportedCodes = supportedLanguages.map { languageCode(forLanguage: $0) }
        return supportedCodes.contains(foreignLanguage ?? "") ? foreignLanguage : nil
    }

    // MARK: Updated new web api at 2025/01/03

    func jsonapi_sApiQuery(text: String, from: Language, to: Language) async throws -> EZQueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        guard !queryTextType().isEmpty else {
            return result
        }

        let enableDictionary = queryTextType().contains(.dictionary)

        guard let foreignLanguage = youdaoDictForeignLanguage(queryModel),
              enableDictionary
        else {
            throw QueryError(type: .unsupported, message: "No results found")
        }

        let w = "\(text)webdict"
        let t = w.count % 10
        let salt = w.md5()
        let key = "Mk6hqtUp33DGGtoS63tTJbMUYjRrG1Lu"
        let sign = "web\(text)\(t)\(key)\(salt)".md5()

        let parameters = [
            "q": text,
            "le": foreignLanguage,
            "client": "web",
            "keyid": "webfanyi",
            "sign": sign,
            "keyfrom": "webdict",
        ]

        let url = "\(kYoudaoDictURL)/jsonapi_s?doctype=json&jsonversion=4"

        do {
            // Get the raw data
            let responseData = try await AF.request(
                url,
                method: .get,
                parameters: parameters
            )
            .serializingData()
            .value

            let respDict = try JSONSerialization.jsonObject(with: responseData)
            let jsonResp = String(data: responseData, encoding: .utf8)
            // Decode the data
            let response = try JSONDecoder().decode(YoudaoDictResponseV2.self, from: responseData)
            print("\(response)")
            result.updateV2(with: response)
            return result
        } catch {
            throw QueryError(
                type: .api,
                message: "Failed to query Youdao dictionary: \(error)"
            )
        }
    }

    // MARK: Keep this api temporarily
    @available(*, deprecated)
    func jsonApiQuery(text: String, from: Language, to: Language) async throws -> EZQueryResult {
        guard !text.isEmpty else {
            throw QueryError(type: .parameter, message: "Translation text is empty")
        }

        guard !queryTextType().isEmpty else {
            return result
        }

        let enableDictionary = queryTextType().contains(.dictionary)

        guard let foreignLanguage = youdaoDictForeignLanguage(queryModel),
              enableDictionary
        else {
            throw QueryError(type: .unsupported, message: "No results found")
        }

        /**
         dicts can be empty, means all dictionaries.

         dicts values from response meta.dicts, for example:

         web_trans, oxfordAdvanceHtml, video_sents, simple, phrs, oxford, syno, collins, word_video, webster, discriminate, ec, ee, blng_sents_part, individual, collins_primary, rel_word, auth_sents_part, media_sents_part, expand_ec, etym, special, senior, music_sents, baike, meta, oxfordAdvance
         */
        let dicts = [["web_trans", "ec", "ce", "newhh", "baike", "wikipedia_digest", "fanyi"]]
        let dictsParams =
            [
                "count": 99,
                "dicts": dicts,
            ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: dictsParams)
        let dictsString = String(data: jsonData, encoding: .utf8) ?? ""

        let parameters = [
            "q": text,
            "le": foreignLanguage,
            "dicts": dictsString,
        ]

        let url = "\(kYoudaoDictURL)/jsonapi"

        do {
            // Get the raw data
            let responseData = try await AF.request(
                url,
                method: .get,
                parameters: parameters
            )
            .serializingData()
            .value

            // Decode the data
            let response = try JSONDecoder().decode(YoudaoDictResponse.self, from: responseData)
            result.update(with: response)
            return result
        } catch {
            throw QueryError(
                type: .api,
                message: "Failed to query Youdao dictionary: \(error)"
            )
        }
    }
}
