//
//  ServiceConfigurationCells.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import SwiftUI

// MARK: - ServiceConfigurationSecureInputCell

struct ServiceConfigurationSecureInputCell: View {
    // MARK: Lifecycle

    init(
        textFieldTitleKey: LocalizedStringKey,
        key: Defaults.Key<String?>,
        placeholder: LocalizedStringKey = "service.configuration.input.placeholder"
    ) {
        self.textFieldTitleKey = textFieldTitleKey
        self.placeholder = placeholder
        _value = .init(key)
    }

    // MARK: Internal

    @Default var value: String?
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey

    var body: some View {
        SecureTextField(title: textFieldTitleKey, placeholder: placeholder, text: $value)
    }
}

// MARK: - ServiceConfigurationInputCell

struct ServiceConfigurationInputCell: View {
    // MARK: Lifecycle

    init(
        textFieldTitleKey: LocalizedStringKey,
        key: Defaults.Key<String?>,
        placeholder: LocalizedStringKey,
        limitLength: Int = Int.max
    ) {
        self.textFieldTitleKey = textFieldTitleKey
        self.placeholder = placeholder
        _value = .init(key)
        self.limitLength = limitLength
    }

    // MARK: Internal

    @Default var value: String?
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey

    var limitLength: Int

    var body: some View {
        TextField(textFieldTitleKey, text: $value ?? "", prompt: Text(placeholder))
            .padding(10.0)
            .onReceive(Just(value)) { _ in
                limit(limitLength)
            }
    }

    // MARK: Private

    private func limit(_ max: Int) {
        if let value, value.count > max {
            self.value = String(value.prefix(max))
        }
    }
}

// MARK: - ServiceConfigurationPickerCell

struct ServiceConfigurationPickerCell<T: Hashable & Defaults.Serializable & EnumLocalizedStringConvertible>: View {
    // MARK: Lifecycle

    init(titleKey: LocalizedStringKey, key: Defaults.Key<T>, values: [T]) {
        self.titleKey = titleKey
        self.values = values
        _value = .init(key)
    }

    // MARK: Internal

    @Default var value: T
    let titleKey: LocalizedStringKey
    let values: [T]

    var body: some View {
        Picker(titleKey, selection: $value) {
            ForEach(values, id: \.self) { value in
                Text(value.title)
            }
        }
        .padding(10.0)
    }
}

// MARK: - ConfigurationToggleViewModel

class ConfigurationToggleViewModel: ObservableObject {
    @Published var isOn = false
}

// MARK: - ServiceConfigurationToggleCell

struct ServiceConfigurationToggleCell: View {
    // MARK: Lifecycle

    init(titleKey: LocalizedStringKey, key: Defaults.Key<String>) {
        self.titleKey = titleKey
        _value = .init(key)
        viewModel.isOn = value == "1"
    }

    // MARK: Internal

    @Default var value: String
    let titleKey: LocalizedStringKey

    @ObservedObject var viewModel = ConfigurationToggleViewModel()

    var body: some View {
        Toggle(titleKey, isOn: $viewModel.isOn)
            .padding(10.0)
            .onChange(of: viewModel.isOn) { newValue in
                value = newValue ? "1" : "0"
            }
    }
}

#Preview {
    Group {
        ServiceConfigurationSecureInputCell(
            textFieldTitleKey: "service.configuration.openai.api_key.title",
            key: .openAIAPIKey,
            placeholder: "service.configuration.openai.api_key.placeholder"
        )

        ServiceConfigurationInputCell(
            textFieldTitleKey: "service.configuration.openai.endpoint.title",
            key: .openAIEndPoint,
            placeholder: "service.configuration.openai.endpoint.placeholder"
        )

        ServiceConfigurationPickerCell(
            titleKey: "service.configuration.openai.usage_status.title",
            key: .openAIServiceUsageStatus,
            values: OpenAIUsageStats.allCases
        )

        ServiceConfigurationToggleCell(
            titleKey: "service.configuration.openai.translation.title",
            key: .openAITranslation
        )
    }
}
