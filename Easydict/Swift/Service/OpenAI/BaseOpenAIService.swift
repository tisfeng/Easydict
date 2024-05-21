//
//  BaseOpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import OpenAI

// MARK: - BaseOpenAIService

// In order to solve the problems caused by inheriting the OpenAI service for custom OpenAI services, we had to add a new base class. FIX https://github.com/tisfeng/Easydict/pull/473#issuecomment-2022587699

@objcMembers
@objc(EZBaseOpenAIService)
public class BaseOpenAIService: LLMStreamService {
    // MARK: Public

    // swiftlint:disable identifier_name
    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let url = URL(string: endpoint)
        let invalidURLError = EZError(type: .param, description: "\(serviceType().rawValue) URL is invalid")
        guard let url, url.isValid else {
            completion(result, invalidURLError)
            return
        }

        updateCompletion = completion

        var resultText = ""

        result.from = from
        result.to = to
        result.isStreamFinished = false

        let queryType = queryType(text: text, from: from, to: to)
        let chats = chatMessages(queryType: queryType, text: text, from: from, to: to)
        let query = ChatQuery(messages: chats, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        openAI.chatsStream(query: query, url: url) { [weak self] res in
            guard let self else { return }

            if !result.isStreamFinished {
                switch res {
                case let .success(chatResult):
                    if let content = chatResult.choices.first?.delta.content {
                        resultText += content
                    }
                    handleResult(queryType: queryType, resultText: resultText, error: nil, completion: completion)
                case let .failure(error):
                    // For stream requests, certain special cases may be normal for the first part of the data transfer, but the final parsing is incorrect.
                    var text: String?
                    var err: Error? = error
                    if !resultText.isEmpty {
                        text = resultText
                        err = nil

                        logError("\(name())-(\(model)) error: \(error.localizedDescription)")
                        logError(String(describing: error))
                    }
                    handleResult(
                        queryType: queryType,
                        resultText: text,
                        error: err,
                        completion: completion
                    )
                }
            }

        } completion: { [weak self] error in
            guard let self else { return }

            if !result.isStreamFinished {
                if let error {
                    handleResult(queryType: queryType, resultText: nil, error: error, completion: completion)
                } else {
                    // If already has error, we do not need to update it.
                    if result.error == nil {
                        resultText = getFinalResultText(text: resultText)

//                        log("\(name())-(\(model)): \(resultText)")
                        handleResult(queryType: queryType, resultText: resultText, error: nil, completion: completion)
                        result.isStreamFinished = true
                    }
                }
            }
        }
    }

    // MARK: Private

    // swiftlint:enable identifier_name

    private func handleResult(
        queryType: EZQueryTextType,
        resultText: String?,
        error: Error?,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        var normalResults: [String]?
        if let resultText {
            normalResults = [resultText.trim()]
        }

        result.isStreamFinished = error != nil
        result.translatedResults = normalResults

        let updateCompletion = {
            self.throttler.throttle { [unowned self] in
                self.updateCompletion?(result, error)
            }
        }

        switch queryType {
        case .sentence, .translation:
            updateCompletion()

        case .dictionary:
            if error != nil {
                result.showBigWord = false
                result.translateResultsTopInset = 0
                updateCompletion()
                return
            }

            result.showBigWord = true
            result.queryText = queryModel.queryText
            result.translateResultsTopInset = 6
            updateCompletion()

        default:
            updateCompletion()
        }
    }
}
