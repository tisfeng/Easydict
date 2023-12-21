//
//  AliService.swift
//  Easydict
//
//  Created by choykarl on 2023/12/20.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import Foundation

@objc(EZAliService)
class AliService: QueryService {
    override func serviceType() -> ServiceType {
        .ali
    }

    override public func link() -> String? {
        "https://translate.alibaba.com/"
    }

    override public func name() -> String {
        NSLocalizedString("ali_translate", comment: "The name of Ali Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary in the API
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        AliTranslateType.supportLanguagesDictionary.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        NSLog("ali Translate does not support OCR")
        throw QueryServiceError.notSupported
    }

    override func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        let transType = AliTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = EZError(type: .unsupportedLanguage, description: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        let request = AF.request("https://translate.alibaba.com/api/translate/text",
                                 method: .get,
                                 parameters: [
                                     "srcLang": transType.sourceLanguage,
                                     "tgtLang": transType.targetLanguage,
                                     "domain": "general",
                                     "query": text,
                                 ])
                                 .validate()
                                 .responseDecodable(of: AliResponse.self) { [weak self] response in
                                     guard let self else { return }
                                     let result = self.result

                                     switch response.result {
                                     case let .success(value):
                                         result.from = from
                                         result.to = to
                                         result.queryText = text
                                         if let data = value.data, let translateText = data.translateText {
                                             result.translatedResults = [translateText.unescapedXML()]
                                             completion(result, nil)
                                         } else {
                                             let ezError = EZError(type: value.httpStatusCode == 500 ? .unsupportedLanguage : .noResultsFound)
                                             ezError.errorDataMessage = value.message ?? "ali translate failed"
                                             completion(result, ezError)
                                         }
                                     case let .failure(error):
                                         NSLog("ali lookup error \(error)")
                                         let ezError = EZError(nsError: error)

                                         if let data = response.data {
                                             do {
                                                 let errorResponse = try JSONDecoder().decode(TencentErrorResponse.self, from: data)
                                                 ezError?.errorDataMessage = errorResponse.response.error.message
                                             } catch {
                                                 NSLog("Failed to decode error response: \(error)")
                                             }
                                         }
                                         completion(result, ezError)
                                     }
                                 }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
