//
//  ServiceConfigurationCells.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI

@available(macOS 13.0, *)
struct ServiceConfigurationSecureInputCell: View {
    @Default var value: String?
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey

    init(
        textFieldTitleKey: LocalizedStringKey,
        key: Defaults.Key<String?>,
        placeholder: LocalizedStringKey = "service.configuration.input.placeholder"
    ) {
        self.textFieldTitleKey = textFieldTitleKey
        self.placeholder = placeholder
        _value = .init(key)
    }

    var body: some View {
        SecureTextField(title: textFieldTitleKey, placeholder: placeholder, text: $value)
    }
}

@available(macOS 13.0, *)
struct ServiceConfigurationInputCell: View {
    @Default var value: String?
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey

    init(textFieldTitleKey: LocalizedStringKey, key: Defaults.Key<String?>, placeholder: LocalizedStringKey) {
        self.textFieldTitleKey = textFieldTitleKey
        self.placeholder = placeholder
        _value = .init(key)
    }

    var body: some View {
        TextField(textFieldTitleKey, text: $value ?? "", prompt: Text(placeholder))
            .padding(10.0)
    }
}

@available(macOS 13.0, *)
struct ServiceConfigurationPickerCell<T: RawRepresentable & Hashable>: View where T.RawValue: StringProtocol {
    @Default var value: String
    let titleKey: LocalizedStringKey
    let values: [T]

    init(titleKey: LocalizedStringKey, key: Defaults.Key<String>, values: [T]) {
        self.titleKey = titleKey
        self.values = values
        _value = .init(key)
    }

    var body: some View {
        Picker(titleKey, selection: $value) {
            ForEach(values, id: \.rawValue) { value in
                Text(value.rawValue)
            }
        }
        .padding(10.0)
    }
}

@available(macOS 13.0, *)
struct ServiceConfigurationToggleCell: View {
    @Default var value: String
    let titleKey: LocalizedStringKey
    @State private var isOn = false

    init(titleKey: LocalizedStringKey, key: Defaults.Key<String>) {
        self.titleKey = titleKey
        _value = .init(key)
        _isOn = State(initialValue: value == "1")
    }

    var body: some View {
        Toggle(titleKey, isOn: $isOn)
            .padding(10.0)
            .onChange(of: isOn) { newValue in
                value = newValue ? "1" : "0"
            }
    }
}

@available(macOS 13.0, *)
#Preview {
    Group {
        ServiceConfigurationSecureInputCell(
            textFieldTitleKey: "service.configuration.openai.api_key.title",
            key: .openAIAPIKey,
            placeholder: "service.configuration.openai.api_key.placeholder"
        )

        ServiceConfigurationInputCell(
            textFieldTitleKey: "service.configuration.openai.domain.title",
            key: .openAIDomain,
            placeholder: "service.configuration.openai.domain.placeholder"
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
    }
}
