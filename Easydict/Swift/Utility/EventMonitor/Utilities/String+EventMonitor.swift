//
//  String+EventMonitor.swift
//  Scoco
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension String {
    /// Removes invisible characters and trims whitespace/newlines.
    func cleanedSelectedText() -> String {
        removeInvisibleChar().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
