//
//  PolishingService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

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

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [[String: String]] {
        polishingMessages(chatQuery)
    }
}
