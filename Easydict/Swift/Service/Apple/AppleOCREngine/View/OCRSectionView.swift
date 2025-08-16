//
//  OCRTextResultsView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI
import Vision

// MARK: - OCRSectionView

/// View for displaying OCR text analysis results
struct OCRSectionView: View {
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
                        ocrSection: section,
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
    let ocrSection: OCRSection
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
                        Text(verbatim: ocrSection.detectedLanguage.description)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    Text(verbatim: "\(ocrSection.observations.count) text observations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Preview text
                if let firstObs = ocrSection.observations.first {
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
                if !ocrSection.mergedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Merged Text:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(ocrSection.mergedText)
                            .font(.body)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
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
                        ForEach(Array(ocrSection.observations.enumerated()), id: \.offset) { index, observation in
                            Text(verbatim: "[\(index)] \"\(observation.firstText)\"")
                                .font(.system(.caption))
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
