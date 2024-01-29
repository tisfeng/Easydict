//
//  OpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

protocol ServiceSecretConfigrable {
    func resetSecret()

    func validate(completion: @escaping (EZQueryResult, Error?) -> Void)
}

extension ServiceSecretConfigrable {
    func resetSecret() {}

    func validate(completion _: @escaping (EZQueryResult, Error?) -> Void) {}
}

extension QueryService: ServiceSecretConfigrable {
    func validate(completion: @escaping (EZQueryResult, Error?) -> Void) {
        resetServiceResult()
        translate("hello world!", from: .english, to: .simplifiedChinese, completion: completion)
    }
}

extension EZOpenAIService {
    func resetSecret() {}

    func validate() {}
}

@available(macOS 13.0, *)
extension EZOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSectionView(headerTitleKey: "service.configuration.openai.header", service: self) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .openAIAPIKey,
                placeholder: "service.configuration.openai.api_key.prompt"
            )
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.translation.title",
                key: .openAITranslation,
                placeholder: "service.configuration.openai.translation.prompt"
            )
        }
    }
}
