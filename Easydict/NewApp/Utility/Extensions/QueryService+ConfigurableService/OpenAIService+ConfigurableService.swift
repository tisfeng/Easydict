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

@available(macOS 13.0, *)
extension EZOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.openAIAPIKey]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .openAIAPIKey,
                placeholder: "service.configuration.openai.api_key.placeholder"
            )
            // endpoint
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.endpoint.title",
                key: .openAIEndPoint,
                placeholder: "service.configuration.openai.endpoint.placeholder"
            )
            // model
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.model.title",
                key: .openAIModel,
                values: OpenAIModels.allCases
            )

            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.translation.title",
                key: .openAITranslation
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.sentence.title",
                key: .openAISentence
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.dictionary.title",
                key: .openAIDictionary
            )
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.usage_status.title",
                key: .openAIServiceUsageStatus,
                values: OpenAIUsageStats.allCases
            )
        }
    }
}

protocol EnumLocalizedStringConvertible {
    var title: String { get }
}

enum OpenAIModels: String, CaseIterable {
    case gpt3_5_turbo_0125 = "gpt-3.5-turbo-0125"
    case gpt4_0125_preview = "gpt-4-0125-preview"
}

extension OpenAIModels: EnumLocalizedStringConvertible {
    var title: String {
        rawValue
    }
}

extension OpenAIModels: Defaults.Serializable {}

enum OpenAIUsageStats: String, CaseIterable {
    case `default` = "0"
    case alwaysOff = "1"
    case alwaysOn = "2"
}

extension OpenAIUsageStats: EnumLocalizedStringConvertible {
    var title: String {
        switch self {
        case .default:
            return NSLocalizedString(
                "service.configuration.openai.usage_status_default.title",
                bundle: .main,
                comment: ""
            )
        case .alwaysOff:
            return NSLocalizedString(
                "service.configuration.openai.usage_status_always_off.title",
                bundle: .main,
                comment: ""
            )
        case .alwaysOn:
            return NSLocalizedString(
                "service.configuration.openai.usage_status_always_on.title",
                bundle: .main,
                comment: ""
            )
        }
    }
}

extension OpenAIUsageStats: Defaults.Serializable {}
