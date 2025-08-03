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
        step: Double = 0.1
    ) {
        self.titleKey = titleKey
        self.storedValueKey = storedValueKey
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step

        self._value = .init(storedValueKey)
    }

    // MARK: Internal

    let titleKey: LocalizedStringKey
    let storedValueKey: Defaults.Key<Double>

    let minValue: Double
    let maxValue: Double
    let step: Double

    @Default var value: Double

    var body: some View {
        HStack {
            Slider(
                value: $value,
                in: minValue ... maxValue,
                step: step
            ) {
                Text(titleKey)
            } minimumValueLabel: {
                Text(minValue.string1f)
                    .font(.body)
            } maximumValueLabel: {
                Text(maxValue.string1f)
                    .font(.body)
            }

            Text(value.string1f)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(10)
    }
}
