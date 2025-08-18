//
//  OCRBandView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI
import Vision

// MARK: - OCRBandView

/// View for displaying OCR band analysis results
struct OCRBandView: View {
    // MARK: Internal

    let bands: [OCRBand]
    @Binding var selectedIndex: Int?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "OCR Band Analysis")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(verbatim: "\(bands.count) bands detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Band cards
                ForEach(Array(bands.enumerated()), id: \.offset) { bandIndex, band in
                    let bandStartIndex = calculateBandStartIndex(bandIndex: bandIndex)

                    OCRBandCard(
                        bandIndex: bandIndex,
                        band: band,
                        selectedSectionIndex: selectedIndex,
                        bandStartIndex: bandStartIndex
                    ) { localSectionIndex in
                        // Calculate global section index
                        let globalIndex = bandStartIndex + localSectionIndex
                        selectedIndex = (selectedIndex == globalIndex) ? nil : globalIndex
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Private

    /// Calculate the starting global index for a specific band
    private func calculateBandStartIndex(bandIndex: Int) -> Int {
        var startIndex = 0
        for i in 0 ..< bandIndex {
            startIndex += bands[i].sections.count
        }
        return startIndex
    }
}

// MARK: - OCRBandCard

/// Card view for displaying a single OCR band with its sections
struct OCRBandCard: View {
    // MARK: Internal

    let bandIndex: Int
    let band: OCRBand
    let selectedSectionIndex: Int?
    let bandStartIndex: Int
    let onSectionTap: (Int) -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Band header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "Band \(bandIndex + 1)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(verbatim: "\(band.sections.count) sections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: .ocrDuration)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemSymbol: .chevronRight)
                        .font(.headline)
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: .ocrDuration), value: isExpanded)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Sections (when expanded)
            if isExpanded {
                ForEach(Array(band.sections.enumerated()), id: \.offset) { sectionIndex, section in
                    let globalSectionIndex = bandStartIndex + sectionIndex
                    let isSelected = selectedSectionIndex == globalSectionIndex

                    OCRSectionCard(
                        sectionIndex: globalSectionIndex,
                        ocrSection: section,
                        isSelected: isSelected,
                        isExpanded: isSelected,
                        bandIndex: bandIndex,
                        localSectionIndex: sectionIndex
                    ) {
                        withAnimation(.easeInOut(duration: .ocrDuration)) {
                            onSectionTap(sectionIndex)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onChange(of: selectedSectionIndex) { newSelectedIndex in
            if let selectedIndex = newSelectedIndex {
                let bandEndIndex = bandStartIndex + band.sections.count - 1
                if selectedIndex >= bandStartIndex, selectedIndex <= bandEndIndex {
                    if !isExpanded {
                        withAnimation(.easeInOut(duration: .ocrDuration)) {
                            isExpanded = true
                        }
                    }
                }
            }
        }
    }

    // MARK: Private

    @State private var isExpanded = true
}

// MARK: - OCRSectionCard

/// Card view for displaying information about a single OCR section
struct OCRSectionCard: View {
    // MARK: Lifecycle

    init(
        sectionIndex: Int,
        ocrSection: OCRSection,
        isSelected: Bool,
        isExpanded: Bool,
        bandIndex: Int? = nil,
        localSectionIndex: Int? = nil,
        onTap: @escaping () -> ()
    ) {
        self.sectionIndex = sectionIndex
        self.ocrSection = ocrSection
        self.isSelected = isSelected
        self.isExpanded = isExpanded
        self.bandIndex = bandIndex
        self.localSectionIndex = localSectionIndex
        self.onTap = onTap
    }

    // MARK: Internal

    let sectionIndex: Int
    let ocrSection: OCRSection
    let isSelected: Bool
    let isExpanded: Bool
    let bandIndex: Int?
    let localSectionIndex: Int?
    let onTap: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let observations = ocrSection.observations

            // Section header
            HStack {
                // Section title and language badge
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(verbatim: "Section \(sectionIndex + 1)")
                            .font(.subheadline)
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

                    Text(verbatim: "\(observations.count) text observations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Section preview text
                if let firstObs = observations.first {
                    let previewText =
                        ocrSection.language.requiresWordSpacing
                            ? firstObs.prefix30
                            : firstObs.prefix20
                    Text(previewText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

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

                // Section text observations
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Text Observations:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
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
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

extension Double {
    static let ocrDuration: Double = 0.15
}
