//
//  AIToolService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

/// A class used for AI Tools such as summary and polishing
/// Based on `BuiltInAIService` and takes `llama3-70b-8192` as the LLM
class AIToolService: BuiltInAIService {
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
}
