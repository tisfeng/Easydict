//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZCustomOpenAIService)
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        let serviceName = Defaults[super.nameKey]
        return serviceName.isEmpty ? NSLocalizedString("custom_openai", comment: "") : serviceName
    }

    public override func serviceType() -> ServiceType {
        .customOpenAI
    }

    // MARK: Internal

    override func serviceTypeWithUniqueIdentifier() -> String {
        guard !uuid.isEmpty else {
            return ServiceType.customOpenAI.rawValue
        }
        return "\(ServiceType.customOpenAI.rawValue)#\(uuid)"
    }

    override func isDuplicatable() -> Bool {
        true
    }

    override func isRemovable(_ type: EZWindowType) -> Bool {
        !uuid.isEmpty
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showNameSection: true,
            showCustomPromptSection: true
        )
    }

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [[String: String]] {
        if enableCustomPrompt {
            let userPrompt = replaceCustomPromptWithVariable(userPrompt)
            let systemPrompt = replaceCustomPromptWithVariable(systemPrompt)
            return [
                chatMessage(role: .user, content: userPrompt),
                chatMessage(role: .system, content: systemPrompt),
            ]
        }
        return super.chatMessageDicts(chatQuery)
    }

    /**
     Convert custom prompt $xxx to variable.

     e.g.
     prompt: Translate the following ${{queryFromLanguage}} text into ${{queryTargetLanguage}}: ${{queryText}}
     runtime prompt: Translate the following English text into Simplified-Chinese: Hello, world

     ${{queryFromLanguage}} --> queryModel.queryFromLanguage.rawValue
     ${{queryTargetLanguage}} --> queryModel.queryTargetLanguage.rawValue
     ${{queryText}} --> queryModel.queryText
     ${{firstLanguage}} --> Configuration.shared.firstLanguage.rawValue
     */
    func replaceCustomPromptWithVariable(_ prompt: String) -> String {
        var runtimePrompt = prompt
        if runtimePrompt.isEmpty {
            return queryModel.queryText
        }

        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{queryFromLanguage}}",
            with: queryModel.queryFromLanguage.rawValue
        )
        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{queryTargetLanguage}}",
            with: queryModel.queryTargetLanguage.rawValue
        )
        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{queryText}}",
            with: queryModel.queryText
        )
        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{firstLanguage}}",
            with: Configuration.shared.firstLanguage.rawValue
        )
        return runtimePrompt
    }
}
