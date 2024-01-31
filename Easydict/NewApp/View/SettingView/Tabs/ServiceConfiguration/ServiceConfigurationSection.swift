//
//  ServiceConfigurationSection.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import SwiftUI

@available(macOS 12.0, *)
struct ServiceStringConfigurationSection<F: View>: View {
    /// Title of text field
    let textFieldTitleKey: LocalizedStringKey
    /// Header of section. If there is no need to add an header, just leave empty string
    let headerTitleKey: LocalizedStringKey
    /// Defaults key for configuration. Please refer to `Configuration` - `Configuration`
    let key: Defaults.Key<String?>
    /// Prompt of text field
    let prompt: LocalizedStringKey
    /// Footer of section. Add comments, footnotes or links to describe the field.
    @ViewBuilder let footer: () -> F

    var body: some View {
        ServiceConfigurationSection(
            headerTitleKey,
            key: key,
            field: { value in
                let value = Binding<String>.init {
                    value.wrappedValue ?? ""
                } set: { newValue in
                    value.wrappedValue = newValue.trimmingCharacters(in: .whitespaces)
                }
                TextField(textFieldTitleKey, text: value, prompt: Text(prompt))
                    .lineLimit(1)
            },
            footer: footer
        )
    }
}

@available(macOS 12.0, *)
struct ServiceConfigurationSection<T: _DefaultsSerializable, F: View, V: View>: View {
    @Default var value: T

    init(
        _ titleKey: LocalizedStringKey,
        key: Defaults.Key<T>,
        @ViewBuilder field: @escaping (Binding<T>) -> V,
        footer: (() -> F)?
    ) {
        self.titleKey = titleKey
        _value = .init(key)
        self.footer = footer
        self.field = field
    }

    let field: (Binding<T>) -> V
    let footer: (() -> F)?

    let titleKey: LocalizedStringKey

    var body: some View {
        Section {
            field($value)
        } header: {
            HStack(alignment: .lastTextBaseline) {
                Text(titleKey)
                Spacer()
                Button("service.configuration.reset") {
                    _value.reset()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .font(.footnote)
            }
        } footer: {
            if let footer {
                footer()
                    .font(.footnote)
            }
        }
    }
}
