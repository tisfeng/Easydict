//
//  ServiceConfigurationSection.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI

@available(macOS 12.0, *)
struct ServiceStringConfigurationSection<F: View>: View {
    let textFieldTitleKey: LocalizedStringKey
    let headerTitleKey: LocalizedStringKey
    let key: Defaults.Key<String?>
    let prompt: LocalizedStringKey
    @ViewBuilder let footer: () -> F

    var body: some View {
        ServiceConfigurationSection(
            headerTitleKey,
            key: key,
            field: { value in
                let value = Binding<String>.init {
                    value.wrappedValue ?? ""
                } set: { newValue in
                    value.wrappedValue = newValue
                }
                TextField(textFieldTitleKey, text: value, prompt: Text(prompt))
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
                Button("service.service_configuration.reset") {
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
