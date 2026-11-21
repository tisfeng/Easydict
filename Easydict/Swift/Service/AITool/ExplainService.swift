//
//  ExplainService.swift
//  Easydict
//
//  Created by tisfeng on 2026/9/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// swiftlint:disable line_length

@objc(EZExplainService)
class ExplainService: AIToolService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("explain_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .explain
    }

    // MARK: Internal

    override var serviceUsageStatusKey: Defaults.Key<ServiceUsageStatus> {
        serviceDefaultsKey(.serviceUsageStatus, defaultValue: .default)
    }

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        let (text, _, _, _, _) = chatQuery.unpack()
        let answerLanguage = MyConfiguration.shared.firstLanguage
        let prompt = explainPrompt(text: text, answerLanguage: answerLanguage)

        let fewShot = [
            chatMessagePair(
                userContent:
                "Using English to explain the following text: \"\"\"spill the tea\"\"\".",
                assistantContent:
                "\"Spill the tea\" is internet slang meaning to share gossip or juicy insider information, especially about someone's private life. It originated in Black American slang and online fandom culture, and became popular through reality TV communities. Use it when asking someone to reveal hidden or exclusive details, e.g., \"Come on, spill the tea about their breakup.\""
            ),
            chatMessagePair(
                userContent:
                "Using Simplified-Chinese to explain the following text: \"\"\"Error: EACCES: permission denied, open '/usr/local/lib/node_modules'\"\"\".",
                assistantContent:
                "这是一个 Node.js 的文件权限错误。EACCES 表示当前用户没有权限读写 '/usr/local/lib/node_modules' 目录，通常在执行 npm install -g 全局安装包时出现，因为该目录归 root 所有。常见解决办法：优先用 nvm 管理 Node.js，让全局目录位于用户主目录内；或者修改该目录归属 sudo chown -R $(whoami) /usr/local/lib/node_modules。不建议长期用 sudo 运行 npm。"
            ),
        ].flatMap { $0 }

        var messages: [ChatMessage] = [
            .init(role: .system, content: explainSystemPrompt),
        ]
        messages.append(contentsOf: fewShot)
        messages.append(.init(role: .user, content: prompt))

        return messages
    }

    // MARK: Private

    private let explainSystemPrompt = """
    You are a knowledgeable assistant skilled at identifying what a given text refers to and explaining it clearly. The input may be a term, an error message, a piece of code, an abbreviation, slang, a sentence, or an everyday object. Explain what it is, its key facts, and relevant context, adapting the depth and format to the input. Prioritize authoritative sources for proper nouns and jargon. Answer in the requested language. Only return the explanation, without redundant quotes or additional notes.
    """

    private func explainPrompt(text: String, answerLanguage: Language) -> String {
        "Using \(answerLanguage.rawValue) to explain the following text: \"\"\"\(text)\"\"\"."
    }
}

// swiftlint:enable line_length
