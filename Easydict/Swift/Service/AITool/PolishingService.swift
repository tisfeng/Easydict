//
//  PolishingService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

@objc(EZPolishingService)
class PolishingService: AIToolService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("polishing_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .polishing
    }

    // MARK: Internal

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        if let textReplacementPromptContext {
            return textReplacementMessages(
                chatQuery,
                context: textReplacementPromptContext
            )
        }
        return polishingMessages(chatQuery)
    }
}

// swiftlint:enable line_length
