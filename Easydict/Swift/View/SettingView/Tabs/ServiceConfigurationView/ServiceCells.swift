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

// MARK: - SecureInputCell

struct SecureInputCell: View {
    // MARK: Lifecycle

    init(
        textFieldTitleKey: LocalizedStringKey,
        key: Defaults.Key<String>,
        placeholder: LocalizedStringKey = "service.configuration.input.placeholder",
        showText: Bool = false
    ) {
        self.textFieldTitleKey = textFieldTitleKey
        self.placeholder = placeholder
        _value = .init(key)
        self.showText = showText
    }

    // MARK: Internal

    @Default var value: String
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @State var showText: Bool

    var body: some View {
        SecureTextField(title: textFieldTitleKey, placeholder: placeholder, text: $value, showText: showText)
    }
}

// MARK: - InputCell

struct InputCell: View {
    // MARK: Lifecycle

    init(
        textFieldTitleKey: LocalizedStringKey,
        key: Defaults.Key<String>,
        placeholder: LocalizedStringKey,
        limitLength: Int = Int.max
    ) {
        self.textFieldTitleKey = textFieldTitleKey
        self.placeholder = placeholder
        _value = .init(key)
        self.limitLength = limitLength
    }

    // MARK: Internal

    @Default var value: String
    let textFieldTitleKey: LocalizedStringKey
    let placeholder: LocalizedStringKey

    var limitLength: Int

    var body: some View {
        TextField(textFieldTitleKey, text: $value, prompt: Text(placeholder))
            .padding(10.0)
            .onReceive(Just(value)) { _ in
                limit(limitLength)
            }
    }

    // MARK: Private

    private func limit(_ max: Int) {
        if value.count > max {
            value = String(value.prefix(max))
        }
    }
}

// MARK: - StaticPickerCell

struct StaticPickerCell<T: Hashable & Defaults.Serializable & EnumLocalizedStringConvertible>: View {
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

// MARK: - PickerCell

struct PickerCell<T: Hashable & Defaults.Serializable & EnumLocalizedStringConvertible>: View {
    // MARK: Lifecycle

    init(titleKey: LocalizedStringKey, selectionKey: Defaults.Key<T>, valuesKey: Defaults.Key<[T]>) {
        self.titleKey = titleKey
        _selection = .init(selectionKey)
        _values = .init(valuesKey)
    }

    // MARK: Internal

    let titleKey: LocalizedStringKey

    @Default var selection: T
    @Default var values: [T]

    var body: some View {
        Picker(titleKey, selection: $selection) {
            ForEach(values, id: \.self) { value in
                Text(value.title)
            }
        }
        .padding(10.0)
    }
}

// MARK: - ToggleViewModel

class ToggleViewModel: ObservableObject {
    // MARK: Lifecycle

    init(key: Defaults.Key<String>) {
        self.key = key
        self._value = .init(key)
        self.isOn = Defaults[key] == "1"
    }

    // MARK: Internal

    let key: Defaults.Key<String>
    @Default var value: String

    @Published var isOn: Bool {
        didSet {
            value = isOn ? "1" : "0"
        }
    }
}

// MARK: - StringToggleCell

/// Since we previously used String for the toggle value, we have to connect String <--> Bool with a viewModel.
/// For new feature, we should use ToggleCell instead of StringToggleCell.
struct StringToggleCell: View {
    // MARK: Lifecycle

    init(titleKey: LocalizedStringKey, key: Defaults.Key<String>) {
        self.titleKey = titleKey
        self.viewModel = ToggleViewModel(key: key)
    }

    // MARK: Internal

    let titleKey: LocalizedStringKey

    var body: some View {
        Toggle(titleKey, isOn: $viewModel.isOn)
            .padding(10.0)
    }

    // MARK: Private

    @ObservedObject private var viewModel: ToggleViewModel
}

// MARK: - ToggleCell

struct ToggleCell: View {
    // MARK: Lifecycle

    init(titleKey: LocalizedStringKey, key: Defaults.Key<Bool>, footnote: LocalizedStringKey? = nil) {
        self.titleKey = titleKey
        self.footnote = footnote
        self._value = .init(key)
    }

    // MARK: Internal

    let titleKey: LocalizedStringKey
    let footnote: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(titleKey, isOn: $value)

            if let footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding(10.0)
    }

    // MARK: Private

    @Default private var value: Bool
}
