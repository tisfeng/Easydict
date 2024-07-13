//
//  AIToolService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

/// A class used for AI Tools such as summary and polishing
class AIToolService: BuiltInAIService {
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

    override var serviceUsageStatusKey: Defaults.Key<ServiceUsageStatus> {
        serviceDefaultsKey(.serviceUsageStatus, defaultValue: .alwaysOff)
    }
}
