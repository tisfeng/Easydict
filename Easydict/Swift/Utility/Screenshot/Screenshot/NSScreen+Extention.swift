//
//  NSScreen+Extention.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/20.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension NSScreen {
    /// Device description string
    var deviceDescriptionString: String {
        // Sort keys to ensure consistent order
        let sortedKeys = deviceDescription.keys.sorted { $0.rawValue < $1.rawValue }

        var description = ""
        for key in sortedKeys {
            if let value = deviceDescription[key] {
                description += "\(key.rawValue): \(value)\n"
            }
        }
        return "{\n\(description)}"
    }

    func isSameScreen(_ other: NSScreen?) -> Bool {
        deviceDescriptionString == other?.deviceDescriptionString
    }

    var bounds: CGRect {
        CGRect(origin: .zero, size: frame.size)
    }
}
