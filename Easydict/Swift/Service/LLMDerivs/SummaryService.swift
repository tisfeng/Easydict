//
//  SummaryService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

@objc(EZSummaryService)
class SummaryService: LLMDerivService {
    public override func name() -> String {
        NSLocalizedString("summary_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .summary
    }

    public override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let url = URL(string: endpoint)
        let invalidURLError = EZError(type: .param, description: "`\(serviceType().rawValue)` endpoint is invalid")
        guard let url, url.isValid else {
            completion(result, invalidURLError)
            return
        }

        var resultText = ""

        result.isStreamFinished = false

        // Set EZQueryTextType as translation since no formatting is needed
        let queryType = EZQueryTextType.translation
        let chatParam = LLMDerivParam(
            text: text,
            sourceLanguage: from,
            serviceType: .summary
        )

        let chatHistory = serviceChatMessage(chatParam)
        guard let chatHistory = chatHistory as? [ChatMessage] else { return }

        let query = ChatQuery(messages: chatHistory, model: model, temperature: 0)
        let openAI = OpenAI(apiToken: apiKey)

        // FIXME: It seems that `control` will cause a memory leak, but it is not clear how to solve it.
        unowned let unownedControl = control

        // TODO: refactor chatsStream with await
        openAI.chatsStream(query: query, url: url, control: unownedControl) { [weak self] res in
            guard let self else { return }

            switch res {
            case let .success(chatResult):
                if let content = chatResult.choices.first?.delta.content {
                    resultText += content
                }
                updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
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
                updateResultText(text, queryType: queryType, error: err, completion: completion)
            }

        } completion: { [weak self] error in
            guard let self else { return }

            if let error {
                updateResultText(nil, queryType: queryType, error: error, completion: completion)
                return
            }

            // If already has error, we do not need to update it.
            if result.error == nil {
                resultText = getFinalResultText(resultText)
//              log("\(name())-(\(model)): \(resultText)")
                updateResultText(resultText, queryType: queryType, error: nil, completion: completion)
                result.isStreamFinished = true
            }
        }
    }
}
