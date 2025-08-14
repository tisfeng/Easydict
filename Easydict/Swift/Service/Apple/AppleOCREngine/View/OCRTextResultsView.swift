//
//  OCRTextResultsView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI
import Vision

// MARK: - OCRTextResultsView

/// View for displaying OCR text analysis results
struct OCRTextResultsView: View {
    // MARK: Internal

    let ocrSections: [OCRSection]
    @Binding var selectedIndex: Int?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "OCR Analysis Results")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(verbatim: "\(ocrSections.count) sections detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Section cards
                ForEach(Array(ocrSections.enumerated()), id: \.offset) { index, section in
                    OCRSectionCard(
                        sectionIndex: index,
                        ocrSections: section,
                        isSelected: selectedIndex == index,
                        isExpanded: selectedIndex == index
                    ) {
                        selectedIndex = index
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - OCRSectionCard

/// Card view for displaying information about a single OCR section
struct OCRSectionCard: View {
    let sectionIndex: Int
    let ocrSections: OCRSection
    let isSelected: Bool
    let isExpanded: Bool
    let onTap: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(verbatim: "Section \(sectionIndex + 1)")
                            .font(.headline)
                            .fontWeight(.medium)

                        // Language badge
                        Text(verbatim: ocrSections.language.description)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    Text(verbatim: "\(ocrSections.observations.count) text observations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Preview text
                if let firstObs = ocrSections.observations.first {
                    Text(firstObs.prefix30)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Expanded content
            if isExpanded {
                Divider()

                // Section merged text
                if !ocrSections.mergedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Merged Text:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(ocrSections.mergedText)
                            .font(.system(size: 14)) // Font.body is 13 pt
                            .padding(10)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 8)

                    Divider()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Text Observations:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(ocrSections.observations.enumerated()), id: \.offset) { index, observation in
                            Text(verbatim: "[\(index)] \"\(observation.firstText)\"")
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.leading, 10)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1)
        }
    }
}
