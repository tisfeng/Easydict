//
//  SliderCell.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Combine // Import Combine for character filtering
import Defaults
import Foundation
import SwiftUI

// MARK: - SliderCell

/// A slider cell that allows the user to select a value within a specified range.
/// Default is used for LLM temperature, which is usually between 0.0 and 2.0.
struct SliderCell: View {
    // MARK: Lifecycle

    init(
        titleKey: LocalizedStringKey,
        storedValueKey: Defaults.Key<Double>,
        minValue: Double = 0,
        maxValue: Double = 2,
    ) {
        self.titleKey = titleKey
        self.storedValueKey = storedValueKey
        self.minValue = minValue
        self.maxValue = maxValue

        self._value = .init(storedValueKey)

        self.viewModel = SliderViewModel(key: storedValueKey)
    }

    // MARK: Internal

    let titleKey: LocalizedStringKey
    let storedValueKey: Defaults.Key<Double>

    let minValue: Double
    let maxValue: Double

    var body: some View {
        HStack {
            Slider(
                value: $value,
                in: minValue ... maxValue
            ) {
                Text(titleKey)
            } minimumValueLabel: {
                Text(minValue.oneDecimalString)
                    .font(.callout)
            } maximumValueLabel: {
                Text(maxValue.oneDecimalString)
                    .font(.callout)
            } onEditingChanged: { editing in
                isEditing = editing
            }
            .onChange(of: value) { newValue in
                // Update the text field value when the slider changes
                if isEditing {
                    viewModel.textFieldValue = newValue.oneDecimalString
                }
            }

            TextField("", text: $viewModel.textFieldValue)
                .frame(width: 40, alignment: .trailing)
                .onChange(of: viewModel.textFieldValue) { newValue in
                    // 1. Filter input: allow digits and decimal point
                    let validText = newValue.filter { "0123456789.".contains($0) }

                    // 2. Try parsing, clamping, and updating the actual value
                    if let doubleValue = Double(validText) {
                        value = doubleValue
                    } else {
                        value = minValue
                    }

                    // 3. Update the text field value
                    if validText != newValue {
                        viewModel.textFieldValue = validText
                    }
                }
        }
        .padding(10)
    }

    // MARK: Private

    @State private var isEditing = false
    @ObservedObject private var viewModel: SliderViewModel

    @Default private var value: Double
}

// MARK: - SliderViewModel

class SliderViewModel: ObservableObject {
    // MARK: Lifecycle

    init(key: Defaults.Key<Double>) {
        self.key = key
        self._value = .init(key)
        self.textFieldValue = Defaults[key].oneDecimalString
    }

    // MARK: Internal

    let key: Defaults.Key<Double>

    @Default var value: Double

    @Published var textFieldValue: String {
        didSet {
            if let doubleValue = Double(textFieldValue) {
                value = doubleValue
            } else {
                value = 0
            }
        }
    }
}
