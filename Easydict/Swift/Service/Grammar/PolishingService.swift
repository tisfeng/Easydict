//
//  PolishingService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

@objc(EZPolishingService)
class PolishingService: BuiltInAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("polishing_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .polishing
    }

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
