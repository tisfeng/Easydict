//
//  FrameChangeDetector.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - InPlaceFrameSignature

/// A compact luminance representation used to avoid running OCR on visually
/// unchanged frames.
struct InPlaceFrameSignature: Equatable, Sendable {
    // MARK: Lifecycle

    init(dimension: Int = 64, samples: [UInt8]) {
        self.dimension = dimension
        self.samples = samples
    }

    // MARK: Internal

    let dimension: Int
    let samples: [UInt8]
}

// MARK: - InPlaceFrameChangeResult

/// Quantifies the visual difference between two region frames.
struct InPlaceFrameChangeResult: Equatable, Sendable {
    let hasChanged: Bool
    let changedTileRatio: Double
    let normalizedMeanDifference: Double
}

// MARK: - InPlaceFrameChangeDetector

/// Produces low-cost frame signatures and applies the product change thresholds.
struct InPlaceFrameChangeDetector: Sendable {
    // MARK: Lifecycle

    init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: Internal

    /// Tunable detector constants kept together for deterministic tests.
    struct Configuration: Equatable, Sendable {
        // MARK: Lifecycle

        init(
            signatureDimension: Int = 64,
            changedSampleThreshold: UInt8 = 8,
            changedTileRatioThreshold: Double = 0.02,
            meanDifferenceThreshold: Double = 0.012
        ) {
            self.signatureDimension = max(1, signatureDimension)
            self.changedSampleThreshold = changedSampleThreshold
            self.changedTileRatioThreshold = changedTileRatioThreshold
            self.meanDifferenceThreshold = meanDifferenceThreshold
        }

        // MARK: Internal

        let signatureDimension: Int
        let changedSampleThreshold: UInt8
        let changedTileRatioThreshold: Double
        let meanDifferenceThreshold: Double
    }

    let configuration: Configuration

    /// Builds a grayscale signature without retaining the full frame pixels.
    func makeSignature(for image: CGImage) -> InPlaceFrameSignature? {
        let dimension = configuration.signatureDimension
        var samples = [UInt8](repeating: 0, count: dimension * dimension)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let rendered = samples.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: dimension,
                height: dimension,
                bitsPerComponent: 8,
                bytesPerRow: dimension,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                return false
            }
            context.interpolationQuality = .low
            context.draw(image, in: CGRect(x: 0, y: 0, width: dimension, height: dimension))
            return true
        }
        guard rendered else { return nil }
        return InPlaceFrameSignature(dimension: dimension, samples: samples)
    }

    /// Compares signatures. An explicitly empty dirty-rect list is an early no-change signal.
    func compare(
        previous: InPlaceFrameSignature,
        current: InPlaceFrameSignature,
        dirtyRects: [CGRect]? = nil
    )
        -> InPlaceFrameChangeResult {
        if let dirtyRects, dirtyRects.isEmpty {
            return InPlaceFrameChangeResult(
                hasChanged: false,
                changedTileRatio: 0,
                normalizedMeanDifference: 0
            )
        }

        guard previous.dimension == current.dimension,
              previous.samples.count == current.samples.count,
              !current.samples.isEmpty
        else {
            return InPlaceFrameChangeResult(
                hasChanged: true,
                changedTileRatio: 1,
                normalizedMeanDifference: 1
            )
        }

        var changedCount = 0
        var totalDifference = 0
        for index in current.samples.indices {
            let difference = abs(Int(current.samples[index]) - Int(previous.samples[index]))
            totalDifference += difference
            if difference >= Int(configuration.changedSampleThreshold) {
                changedCount += 1
            }
        }

        let count = Double(current.samples.count)
        let changedRatio = Double(changedCount) / count
        let meanDifference = Double(totalDifference) / count / 255
        return InPlaceFrameChangeResult(
            hasChanged: changedRatio >= configuration.changedTileRatioThreshold
                || meanDifference >= configuration.meanDifferenceThreshold,
            changedTileRatio: changedRatio,
            normalizedMeanDifference: meanDifference
        )
    }
}
