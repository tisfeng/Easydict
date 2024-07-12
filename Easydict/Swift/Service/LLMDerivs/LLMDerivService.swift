//
//  LLMDerivService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

/// A class used for LLM derivatives such as summary and polishing
/// Based on `BuiltInAIService` and takes `llama3-70b-8192` as the LLM
class LLMDerivService: BuiltInAIService {
    // MARK: Public

    public override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showNameSection: false,
            showAPIKeySection: false,
            showEndpointSection: false,
            showSupportedModelsSection: false,
            showUsedModelSection: false,
            showTranslationToggle: false,
            showSentenceToggle: false,
            showDictionaryToggle: false,
            showUsageStatusPicker: true
        )
    }

    // MARK: Internal

    override var defaultModels: [String] {
        ["llama3-70b-8192"]
    }
}
