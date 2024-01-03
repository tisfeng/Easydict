//
//  GeminiService.swift
//  Easydict
//
//  Created by Jerry on 2024-01-02.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import GoogleGenerativeAI

@objc(EZGeminiService)
public final class GeminiService: QueryService {
    override public func serviceType() -> ServiceType {
        .gemini
    }

    override public func link() -> String? {
        "https://bard.google.com/chat"
    }

    override public func name() -> String {
        NSLocalizedString("gemini_translate", comment: "The name of Gemini Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary.
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        GeminiTranslateType.supportLanguagesDictionary.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        NSLog("Gemini Translate does not support OCR")
        throw QueryServiceError.notSupported
    }

    override public func needPrivateAPIKey() -> Bool {
        true
    }

    override public func hasPrivateAPIKey() -> Bool {
        if apiKey == defaultAPIKey {
            return false
        }
        return true
    }

    private let defaultAPIKey = "" /* .decryptAES() */

    // easydict://writeKeyValue?EZGeminiAPIKey=xxx
    private var apiKey: String {
        let apiKey = UserDefaults.standard.string(forKey: EZGeminiAPIKey)
        if let apiKey, !apiKey.isEmpty {
            return apiKey
        } else {
            return defaultAPIKey
        }
    }

    override public func autoConvertTraditionalChinese() -> Bool {
        true
    }

    override public func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        Task {
            // https://github.com/google/generative-ai-swift
            do {
                var resultString = ""
                let prompt = "translate this \(from.rawValue) text into \(to.rawValue): \(text)"
                print("gemini prompt: \(prompt)")
                let model = GenerativeModel(name: "gemini-pro", apiKey: apiKey)
                let outputContentStream = model.generateContentStream(prompt)

                // stream response
                for try await outputContent in outputContentStream {
                    guard let line = outputContent.text else {
                        return
                    }

                    print("gemini response: \(line)")
                    resultString += line
                    result.translatedResults = [resultString]
                    completion(result, nil)
                }
            } catch {
                print(error.localizedDescription)
                completion(result, error)
            }
        }
    }
}
