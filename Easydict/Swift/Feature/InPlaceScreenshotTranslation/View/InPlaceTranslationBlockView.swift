//
//  InPlaceTranslationBlockView.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SwiftUI

// MARK: - InPlaceTranslationBlockView

/// Draws one translated section inside its mapped screenshot rectangle while
/// keeping selection, overflow, and copy actions keyboard accessible.
struct InPlaceTranslationBlockView: View {
    // MARK: Internal

    let translatedBlock: InPlaceTranslatedBlock
    let sourceImage: CGImage
    let displayRect: CGRect
    let rotation: Angle
    let isSelected: Bool
    let onSelect: () -> ()
    let onCopy: () -> ()

    var body: some View {
        let shownText = translatedBlock.translatedText ?? translatedBlock.block.sourceText
        let layout = InPlaceBlockTextLayout.fit(text: shownText, in: displayRect.size)
        let appearance = InPlaceBlockAppearance.sample(
            image: sourceImage,
            normalizedRect: translatedBlock.block.normalizedRect
        )

        Button {
            onSelect()
            if layout.isOverflowing {
                showsDetails = true
            }
        } label: {
            Text(verbatim: shownText)
                .font(.system(size: layout.fontSize, weight: .medium))
                .foregroundStyle(appearance.foregroundColor)
                .lineLimit(layout.lineLimit)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .padding(3)
                .frame(width: displayRect.width, height: displayRect.height, alignment: .center)
                .background {
                    blockBackground(appearance)
                }
        }
        .buttonStyle(.plain)
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(
                    isSelected || isHovering || isFocused
                        || colorSchemeContrast == .increased
                        ? Color.accentColor
                        : .clear,
                    lineWidth: isSelected || isFocused || colorSchemeContrast == .increased
                        ? 2
                        : 1
                )
        }
        .overlay(alignment: .topTrailing) {
            if case .failed = translatedBlock.status {
                Text(verbatim: "!")
                    .font(.caption2.bold())
                    .foregroundStyle(appearance.foregroundColor)
                    .padding(2)
                    .background(appearance.backgroundColor, in: Circle())
            }
        }
        .padding(.horizontal, max(0, (28 - displayRect.width) / 2))
        .padding(.vertical, max(0, (28 - displayRect.height) / 2))
        .rotationEffect(rotation)
        .position(x: displayRect.midX, y: displayRect.midY)
        .contentShape(Rectangle())
        .focused($isFocused)
        .onHover { isHovering = $0 }
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                onSelect()
                onCopy()
            }
        )
        .contextMenu {
            Button("in_place_screenshot_translation.toolbar.copy", action: onCopy)
            Button("in_place_screenshot_translation.block.show_details") {
                showsDetails = true
            }
        }
        .popover(isPresented: $showsDetails, arrowEdge: .bottom) {
            detailsPopover
        }
        .help(
            layout.isOverflowing
                ? Text("in_place_screenshot_translation.block.show_details")
                : Text("in_place_screenshot_translation.toolbar.copy")
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(Text(statusLocalizationKey))
        .accessibilityHint(Text(accessibilityHintKey(isOverflowing: layout.isOverflowing)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: Text("in_place_screenshot_translation.toolbar.copy")) {
            onCopy()
        }
    }

    // MARK: Private

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @FocusState private var isFocused: Bool
    @State private var isHovering = false
    @State private var showsDetails = false

    private var accessibilityDescription: Text {
        Text("in_place_screenshot_translation.display.original")
            + Text(verbatim: ": \(translatedBlock.block.sourceText). ")
            + Text("in_place_screenshot_translation.display.translated")
            + Text(verbatim: ": \(translatedBlock.translatedText ?? ""). ")
            + Text(statusLocalizationKey)
    }

    private var statusLocalizationKey: LocalizedStringKey {
        switch translatedBlock.status {
        case .pending:
            "in_place_screenshot_translation.status.translating"
        case .translated:
            "in_place_screenshot_translation.status.ready"
        case .failed:
            "in_place_screenshot_translation.status.partial_failure"
        }
    }

    private var detailsPopover: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("in_place_screenshot_translation.display.original")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: translatedBlock.block.sourceText)
                    .textSelection(.enabled)
                Divider()
                Text("in_place_screenshot_translation.display.translated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: translatedBlock.translatedText ?? "")
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(
            minWidth: 240,
            idealWidth: 320,
            maxWidth: 420,
            minHeight: 100,
            idealHeight: 220,
            maxHeight: 360,
            alignment: .leading
        )
        .padding(12)
    }

    @ViewBuilder
    private func blockBackground(_ appearance: InPlaceBlockAppearance) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        if reduceTransparency || !appearance.isHighVariance {
            shape.fill(appearance.backgroundColor.opacity(reduceTransparency ? 1 : 0.92))
        } else {
            shape
                .fill(.regularMaterial)
                .overlay {
                    shape.fill(appearance.backgroundColor.opacity(0.84))
                }
        }
    }

    private func accessibilityHintKey(isOverflowing: Bool) -> LocalizedStringKey {
        isOverflowing
            ? "in_place_screenshot_translation.block.show_details"
            : "in_place_screenshot_translation.toolbar.copy"
    }
}

// MARK: - InPlaceBlockTextLayout

/// Uses AppKit text measurement and a bounded binary search so translated text
/// receives the largest fitting system font without crossing adjacent blocks.
private struct InPlaceBlockTextLayout {
    // MARK: Internal

    let fontSize: CGFloat
    let lineLimit: Int?
    let isOverflowing: Bool

    static func fit(text: String, in size: CGSize) -> InPlaceBlockTextLayout {
        let contentSize = CGSize(width: max(1, size.width - 6), height: max(1, size.height - 6))
        let minimumFontSize: CGFloat = 9
        let maximumFontSize = min(40, max(minimumFontSize, contentSize.height * 0.8))

        guard fits(text: text, fontSize: minimumFontSize, in: contentSize) else {
            let lineHeight = NSFont.systemFont(ofSize: minimumFontSize, weight: .medium)
                .boundingRectForFont.height
            return InPlaceBlockTextLayout(
                fontSize: minimumFontSize,
                lineLimit: max(1, Int(contentSize.height / max(1, lineHeight))),
                isOverflowing: true
            )
        }

        var lower = minimumFontSize
        var upper = maximumFontSize
        for _ in 0 ..< 8 {
            let candidate = (lower + upper) / 2
            if fits(text: text, fontSize: candidate, in: contentSize) {
                lower = candidate
            } else {
                upper = candidate
            }
        }
        return InPlaceBlockTextLayout(fontSize: lower, lineLimit: nil, isOverflowing: false)
    }

    // MARK: Private

    private static func fits(text: String, fontSize: CGFloat, in size: CGSize) -> Bool {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return bounds.width <= size.width + 0.5 && bounds.height <= size.height + 0.5
    }
}

// MARK: - InPlaceBlockAppearance

/// Samples a tiny in-memory crop to choose a stable mask color, variance mode,
/// and black/white foreground with WCAG-style luminance contrast.
private struct InPlaceBlockAppearance {
    // MARK: Internal

    let backgroundColor: Color
    let foregroundColor: Color
    let isHighVariance: Bool

    static func sample(image: CGImage, normalizedRect: CGRect) -> InPlaceBlockAppearance {
        guard let samples = pixelSamples(image: image, normalizedRect: normalizedRect),
              !samples.isEmpty
        else {
            return InPlaceBlockAppearance(
                backgroundColor: Color(nsColor: .windowBackgroundColor),
                foregroundColor: .primary,
                isHighVariance: false
            )
        }

        let red = median(samples.map(\.red))
        let green = median(samples.map(\.green))
        let blue = median(samples.map(\.blue))
        let luminance = relativeLuminance(red: red, green: green, blue: blue)
        let luminances = samples.map {
            relativeLuminance(red: $0.red, green: $0.green, blue: $0.blue)
        }
        let variance = luminances.reduce(0) { $0 + pow($1 - luminance, 2) }
            / Double(luminances.count)
        let whiteContrast = 1.05 / (luminance + 0.05)
        let blackContrast = (luminance + 0.05) / 0.05

        return InPlaceBlockAppearance(
            backgroundColor: Color(
                nsColor: NSColor(
                    srgbRed: red,
                    green: green,
                    blue: blue,
                    alpha: 1
                )
            ),
            foregroundColor: whiteContrast >= blackContrast ? .white : .black,
            isHighVariance: variance.squareRoot() >= 0.12
        )
    }

    // MARK: Private

    private struct PixelSample {
        let red: Double
        let green: Double
        let blue: Double
    }

    private static func pixelSamples(
        image: CGImage,
        normalizedRect: CGRect
    )
        -> [PixelSample]? {
        let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let pixelRect = CGRect(
            x: normalizedRect.minX * CGFloat(image.width),
            y: normalizedRect.minY * CGFloat(image.height),
            width: normalizedRect.width * CGFloat(image.width),
            height: normalizedRect.height * CGFloat(image.height)
        ).integral.intersection(imageBounds)
        guard !pixelRect.isNull, pixelRect.width >= 1, pixelRect.height >= 1,
              let crop = image.cropping(to: pixelRect)
        else {
            return nil
        }

        let dimension = 8
        var bytes = [UInt8](repeating: 0, count: dimension * dimension * 4)
        let rendered = bytes.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(
                data: storage.baseAddress,
                width: dimension,
                height: dimension,
                bitsPerComponent: 8,
                bytesPerRow: dimension * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.interpolationQuality = .low
            context.draw(crop, in: CGRect(x: 0, y: 0, width: dimension, height: dimension))
            return true
        }
        guard rendered else { return nil }

        return stride(from: 0, to: bytes.count, by: 4).map { index in
            PixelSample(
                red: Double(bytes[index]) / 255,
                green: Double(bytes[index + 1]) / 255,
                blue: Double(bytes[index + 2]) / 255
            )
        }
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    private static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func linear(_ value: Double) -> Double {
            value <= 0.040_45
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.212_6 * linear(red) + 0.715_2 * linear(green) + 0.072_2 * linear(blue)
    }
}
