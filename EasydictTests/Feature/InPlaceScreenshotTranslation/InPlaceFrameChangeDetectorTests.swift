//
//  InPlaceFrameChangeDetectorTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Testing

@testable import Easydict

/// Locks down the visual-diff gates that prevent redundant live OCR and translation work.
@Suite("In-place Frame Change Detector", .tags(.inPlaceTranslation, .unit))
struct InPlaceFrameChangeDetectorTests {
    // MARK: Internal

    @Test("Identical signatures do not trigger processing")
    func ignoresIdenticalFrames() {
        let signature = InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 80))

        let result = InPlaceFrameChangeDetector().compare(
            previous: signature,
            current: signature
        )

        #expect(!result.hasChanged)
        #expect(result.changedTileRatio == 0)
        #expect(result.normalizedMeanDifference == 0)
    }

    @Test("An explicitly empty dirty-rect list is an early no-change signal")
    func respectsEmptyDirtyRectMetadata() {
        let result = InPlaceFrameChangeDetector().compare(
            previous: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 0)),
            current: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 255)),
            dirtyRects: []
        )

        #expect(!result.hasChanged)
        #expect(result.changedTileRatio == 0)
        #expect(result.normalizedMeanDifference == 0)
    }

    @Test("Small encoding noise remains below both product thresholds")
    func ignoresLowAmplitudeNoise() {
        let result = InPlaceFrameChangeDetector().compare(
            previous: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 0)),
            current: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 1))
        )

        #expect(!result.hasChanged)
        #expect(result.changedTileRatio == 0)
        #expect(result.normalizedMeanDifference < 0.012)
    }

    @Test("One strongly changed tile crosses the changed-area threshold")
    func detectsLocalizedContentChange() {
        var current = samples(repeating: 0)
        current[7] = 255

        let result = InPlaceFrameChangeDetector().compare(
            previous: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 0)),
            current: InPlaceFrameSignature(dimension: 4, samples: current)
        )

        #expect(result.hasChanged)
        #expect(result.changedTileRatio == 1.0 / 16.0)
        #expect(result.normalizedMeanDifference == 1.0 / 16.0)
    }

    @Test("Distributed low-amplitude change can cross the mean-difference threshold")
    func detectsDistributedContentChange() {
        let result = InPlaceFrameChangeDetector().compare(
            previous: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 0)),
            current: InPlaceFrameSignature(dimension: 4, samples: samples(repeating: 4))
        )

        #expect(result.hasChanged)
        #expect(result.changedTileRatio == 0)
        #expect(result.normalizedMeanDifference > 0.012)
    }

    @Test("Incompatible signatures are conservatively treated as changed")
    func treatsIncompatibleSignaturesAsChanged() {
        let result = InPlaceFrameChangeDetector().compare(
            previous: InPlaceFrameSignature(dimension: 2, samples: [0, 0, 0, 0]),
            current: InPlaceFrameSignature(dimension: 3, samples: samples(repeating: 0))
        )

        #expect(result == .init(
            hasChanged: true,
            changedTileRatio: 1,
            normalizedMeanDifference: 1
        ))
    }

    @Test("Signature generation downsamples a solid frame to the configured dimension")
    func generatesConfiguredSignature() throws {
        let detector = InPlaceFrameChangeDetector(
            configuration: .init(signatureDimension: 4)
        )
        let image = try #require(makeSolidImage(gray: 1))

        let signature = try #require(detector.makeSignature(for: image))

        #expect(signature.dimension == 4)
        #expect(signature.samples.count == 16)
        #expect(signature.samples.allSatisfy { $0 >= 250 })
    }

    // MARK: Private

    private func samples(repeating value: UInt8) -> [UInt8] {
        [UInt8](repeating: value, count: 16)
    }

    private func makeSolidImage(gray: CGFloat) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: 8,
            height: 8,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(CGColor(gray: gray, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return context.makeImage()
    }
}
