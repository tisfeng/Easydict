//
//  OllamaService.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZOllamaService)
class OllamaService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("ollama_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .ollama
    }

    // MARK: Internal

    override var defaultEndpoint: String {
        "http://localhost:11434/v1/chat/completions"
    }

    override var observeKeys: [Defaults.Key<String>] {
        [supportedModelsKey]
    }

    override var isSentenceEnabledByDefault: Bool {
        false
    }

    override var isDictionaryEnabledByDefault: Bool {
        false
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showAPIKeySection: false
        )
    }
}
