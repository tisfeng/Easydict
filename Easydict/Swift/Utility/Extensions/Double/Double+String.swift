//
//  Double+String.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - Double Extensions

/// Convert double to string with one decimal place.
/// - Example:
///   - 1 -> "1.0"
///   - 1.234 -> "1.2"
extension Double {
    var oneDecimalString: String {
        String(format: "%.1f", self)
    }

    var twoDecimalString: String {
        String(format: "%.2f", self)
    }

    var threeDecimalString: String {
        String(format: "%.3f", self)
    }
}
