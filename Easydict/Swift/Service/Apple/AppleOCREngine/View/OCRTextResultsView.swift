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
    let sectionMergedTexts: [String]
    @Binding var selectedSectionIndex: Int?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("OCR Analysis Results")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(sections.count) sections detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Section cards
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    let sectionMergedText =
                        index < sectionMergedTexts.count ? sectionMergedTexts[index] : ""
                    OCRSectionCard(
                        sectionIndex: index,
                        observations: section,
                        sectionMergedText: sectionMergedText,
                        isSelected: selectedSectionIndex == index,
                        isExpanded: selectedSectionIndex == index
                    ) {
                        selectedSectionIndex = index
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
    let sectionMergedText: String
    let isSelected: Bool
    let isExpanded: Bool
    let onTap: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Section \(sectionIndex + 1)")
                        .font(.headline)
                        .fontWeight(.medium)

                    Text("\(observations.count) text observations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Preview text
                if let firstObs = observations.first {
                    Text(firstObs.prefix20)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // Expanded content
            if isExpanded {
                Divider()

                // Section merged text (if available)
                if !sectionMergedText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Merged Text:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(sectionMergedText)
                            .font(.body)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .textSelection(.enabled)
                    }
                    .padding(.top, 4)

                    Divider()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Text Observations:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("[\(index)] \"\(observation.firstText)\"")
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
