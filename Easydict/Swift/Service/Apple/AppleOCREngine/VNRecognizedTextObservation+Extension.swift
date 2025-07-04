//
//  VNRecognizedTextObservation.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Vision

// MARK: - VNRecognizedTextObservation Extension

extension VNRecognizedTextObservation {
    /// A computed property to get the top candidate string, returns empty string if not available.
    var firstText: String {
        topCandidates(1).first?.string ?? ""
    }

    /// Custom description providing text content and bounding box information
    open override var description: String {
        let boundRect = boundingBox
        return String(
            format: "Text: \"%@\", { x=%.3f, y=%.3f, width=%.3f, height=%.3f }",
            firstText,
            boundRect.origin.x,
            boundRect.origin.y,
            boundRect.size.width,
            boundRect.size.height
        )
    }
}

extension VNRecognizedTextObservation {
    private static var joinedStringKey: UInt8 = 0

    var joinedString: String? {
        get { objc_getAssociatedObject(self, &Self.joinedStringKey) as? String }
        set { objc_setAssociatedObject(self, &Self.joinedStringKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}

// MARK: - Array Extension for Better Printing

extension Array where Element == VNRecognizedTextObservation {
    /// Get a nicely formatted string representation of text observations with indexes
    var formattedDescription: String {
        if isEmpty {
            return "[]"
        }

        var result = "[\n"
        for (index, observation) in enumerated() {
            result += "  [\(index)] \(observation.description)"
            if index < count - 1 {
                result += ",\n"
            } else {
                result += "\n"
            }
        }
        result += "]"
        return result
    }

    /// Extract just the recognized text strings from observations
    var recognizedTexts: [String] {
        map { $0.firstText }
    }
}
