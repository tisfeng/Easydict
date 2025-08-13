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

    let sections: [[VNRecognizedTextObservation]]
    @Binding var selectedIndex: Int?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "OCR Analysis Results")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(verbatim: "\(sections.count) sections detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Section cards
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    let mergedText = section.mergedText ?? ""
                    OCRSectionCard(
                        sectionIndex: index,
                        observations: section,
                        mergedText: mergedText,
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
    let observations: [VNRecognizedTextObservation]
    let mergedText: String
    let isSelected: Bool
    let isExpanded: Bool
    let onTap: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Section \(sectionIndex + 1)")
                        .font(.headline)
                        .fontWeight(.medium)

                    Text(verbatim: "\(observations.count) text observations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Preview text
                if let firstObs = observations.first {
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

                // Section merged text (if available)
                if !mergedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Merged Text:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(mergedText)
                            .font(.body)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
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
                        ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
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
