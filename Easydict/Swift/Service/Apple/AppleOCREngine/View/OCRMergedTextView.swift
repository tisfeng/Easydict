//
//  OCRMergedTextView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/16.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI

// MARK: - OCRMergedTextView

/// A view that displays the final merged OCR text with section-based color coding
struct OCRMergedTextView: View {
    // MARK: Internal

    let bands: [OCRBand]
    let mergedText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: "All Merged Text")
                .font(.headline)
                .padding(.horizontal)

            ScrollView {
                Text(createAttributedMergedText())
                    .font(.system(size: 14)) // Font.body is 13 pt
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: Private

    /// Creates an attributed string with different background colors for each section
    private func createAttributedMergedText() -> AttributedString {
        var attributedString = AttributedString(mergedText)

        // Define colors for different sections
        let sectionColors: [Color] = [.blue, .green, .orange, .purple]

        var searchStartIndex = attributedString.startIndex

        // Get all sections from bands
        let allSections = bands.flatMap { $0.sections }

        for (sectionIndex, section) in allSections.enumerated() {
            let colorIndex = sectionIndex % sectionColors.count
            let sectionColor = sectionColors[colorIndex]
            let sectionText = section.mergedText

            // Find the range of this section's text in the merged text
            if let range = attributedString[searchStartIndex...].range(of: sectionText) {
                // Set background color for this section's text
                attributedString[range].backgroundColor = sectionColor.opacity(0.2)

                // Update search start index to continue searching after this match
                searchStartIndex = range.upperBound
            }
        }

        return attributedString
    }
}

// MARK: - Preview

#Preview {
    let mockBands: [OCRBand] = []

    return OCRMergedTextView(
        bands: mockBands,
        mergedText: "Sample merged text for preview"
    )
    .frame(width: 400, height: 600)
}
