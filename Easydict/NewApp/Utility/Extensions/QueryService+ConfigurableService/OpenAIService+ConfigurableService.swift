//
//  OpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

// MARK: - EZOpenAIService + ConfigurableService

@available(macOS 13.0, *)
extension EZOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        OpenAIServiceConfigurationView(service: self)
    }
}

// MARK: - OpenAIServiceConfigurationView

@available(macOS 13.0, *)
private struct OpenAIServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: EZOpenAIService) {
        self.service = service
        self.viewModel = OpenAIServiceViewModel(service: service)
    }

    // MARK: Internal

    let service: EZOpenAIService

    var body: some View {
        ServiceConfigurationSecretSectionView(
            service: service, observeKeys: [.openAIAPIKey]
        ) {
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
        .onDisappear {
            viewModel.invalidate()
        }
    }

    // MARK: Private

    @ObservedObject private var viewModel: OpenAIServiceViewModel
}

// MARK: - OpenAIServiceViewModel

private class OpenAIServiceViewModel: ObservableObject {
    // MARK: Lifecycle

    init(service: OpenAILikeService) {
        self.service = service
        cancellables.append(
            Defaults.publisher(.openAIModel, options: [])
                .removeDuplicates()
                .sink { _ in
                    self.serviceConfigChanged()
                }
        )
    }

    // MARK: Internal

    let service: OpenAILikeService

    @Default(.openAIModel) var model

    func invalidate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: Private

    private var cancellables: [AnyCancellable] = []

    private func serviceConfigChanged() {
        let userInfo: [String: Any] = [
            EZWindowTypeKey: service.windowType.rawValue,
            EZServiceTypeKey: service.serviceType().rawValue,
        ]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
}

// MARK: - EnumLocalizedStringConvertible

protocol EnumLocalizedStringConvertible {
    var title: String { get }
}

// MARK: - OpenAIModels

// swiftlint:disable identifier_name
enum OpenAIModels: String, CaseIterable {
    case gpt3_5_turbo_0125 = "gpt-3.5-turbo-0125"
    case gpt4_0125_preview = "gpt-4-0125-preview"
}

// MARK: EnumLocalizedStringConvertible

// swiftlint:enable identifier_name

extension OpenAIModels: EnumLocalizedStringConvertible {
    var title: String {
        rawValue
    }
}

// MARK: Defaults.Serializable

extension OpenAIModels: Defaults.Serializable {}

// MARK: - OpenAIUsageStats

enum OpenAIUsageStats: String, CaseIterable {
    case `default` = "0"
    case alwaysOff = "1"
    case alwaysOn = "2"
}

// MARK: EnumLocalizedStringConvertible

extension OpenAIUsageStats: EnumLocalizedStringConvertible {
    var title: String {
        switch self {
        case .default:
            "service.configuration.openai.usage_status_default.title".localized
        case .alwaysOff:
            "service.configuration.openai.usage_status_always_off.title".localized
        case .alwaysOn:
            "service.configuration.openai.usage_status_always_on.title".localized
        }
    }
}

// MARK: Defaults.Serializable

extension OpenAIUsageStats: Defaults.Serializable {}
