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

class ServiceConfigurationViewModel: ObservableObject {
    @Published var isAlertPresented = false
    @Published var isValidating = false
    @Published var alertMessage: LocalizedStringKey = ""
    @Published var isValidateEnabled = false
}


@available(macOS 13.0, *)
struct ServiceConfigurationSectionView<Content: View>: View {
    let service: QueryService
    let headerTitleKey: LocalizedStringKey
    let content: Content

    @ObservedObject private var serviceConfigViewModel = ServiceConfigurationViewModel()

    init(headerTitleKey: LocalizedStringKey, service: QueryService, @ViewBuilder content: () -> Content) {
        self.headerTitleKey = headerTitleKey
        self.service = service
        self.content = content()
    }
    
    var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(headerTitleKey)
            Spacer()
            Button("service.configuration.reset") {
                service.resetSecret()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .font(.footnote)
        }
    }
    
    var footer: some View {
        Button {
            validate()
        } label: {
            Group {
                if serviceConfigViewModel.isValidating {
                    ProgressView()
                        .controlSize(.small)
                        .progressViewStyle(.circular)
                } else {
                    Text("service.configuration.validate")
                }
            }
        }
        .disabled(serviceConfigViewModel.isValidating || !service.hasPrivateAPIKey())
    }

    var body: some View {
        Section {
            content
        } header: {
            header
        } footer: {
            footer
        }
        .alert(isPresented: $serviceConfigViewModel.isAlertPresented) {
            Alert(title: Text(serviceConfigViewModel.alertMessage))
        }
    }
    
    func validate() {
        serviceConfigViewModel.isValidating.toggle()
        service.validate { _, error in
            serviceConfigViewModel.alertMessage = error == nil ? "service.configuration.validation_success" : "service.configuration.validation_fail"
            print("\(service.serviceType()) validate \(error == nil ? "success" : "fail")!")
            serviceConfigViewModel.isValidating.toggle()
            serviceConfigViewModel.isAlertPresented.toggle()
        }
    }
}

@available(macOS 13.0, *)
struct ServiceConfigurationSecureInputCell: View {
    @Default var value: String?
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey

    init(textFieldTitleKey: LocalizedStringKey, key: Defaults.Key<String?>, placeholder: LocalizedStringKey) {
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
        HStack {
            TextField(textFieldTitleKey, text: $value ?? "", prompt: Text(placeholder))
            // make UI consistent with secure input view
            Spacer()
        }
    }
}
