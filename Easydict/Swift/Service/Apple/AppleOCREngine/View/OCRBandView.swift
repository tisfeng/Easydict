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
                        .font(.headline)

                    Text(verbatim: "\(bands.count) bands detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Band cards
                ForEach(bands.indices, id: \.self) { bandIndex in
                    let band = bands[bandIndex]
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

                Button(action: toggleExpansion) {
                    Image(systemSymbol: .chevronRight)
                        .font(.headline)
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: .ocrDuration), value: isExpanded)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture(perform: toggleExpansion)

            // Sections (when expanded)
            if isExpanded {
                ForEach(band.sections.indices, id: \.self) { sectionIndex in
                    let section = band.sections[sectionIndex]
                    let globalSectionIndex = bandStartIndex + sectionIndex
                    let isSelected = selectedSectionIndex == globalSectionIndex

                    OCRSectionCard(
                        sectionIndex: globalSectionIndex,
                        ocrSection: section,
                        isSelected: isSelected
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

    /// Toggles the expansion state of the band card
    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: .ocrDuration)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - OCRSectionCard

/// Card view for displaying information about a single OCR section
struct OCRSectionCard: View {
    // MARK: Lifecycle

    init(
        sectionIndex: Int,
        ocrSection: OCRSection,
        isSelected: Bool,
        onTap: @escaping () -> ()
    ) {
        self.sectionIndex = sectionIndex
        self.ocrSection = ocrSection
        self.isSelected = isSelected
        self.onTap = onTap
    }

    // MARK: Internal

    let sectionIndex: Int
    let ocrSection: OCRSection
    let isSelected: Bool
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
                            .fontWeight(.semibold)

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
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture(perform: onTap)

            if isSelected {
                Divider().padding(.vertical, 4)

                // Section merged text
                if !ocrSection.mergedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Merged Text:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(ocrSection.mergedText)
                            .font(.body)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 10)

                    Divider().padding(.vertical, 4)
                }

                // Section text observations
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Text Observations:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(observations.indices, id: \.self) { index in
                            let observation = observations[index]
                            Text(verbatim: "[\(index)] \"\(observation.firstText)\"")
                                .font(.system(.caption))
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.leading, 10)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
            }
        }
        .padding(8)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

extension Double {
    /// Duration for OCR animations
    static let ocrDuration: Double = 0.15
}
