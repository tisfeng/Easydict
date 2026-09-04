//
//  ScreenshotSelectionTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Testing

@testable import Easydict

/// Verifies that a captured top-left display region maps back to AppKit global coordinates.
@Suite("Screenshot Selection", .tags(.inPlaceTranslation, .screenshot, .unit))
struct ScreenshotSelectionTests {
    // MARK: Internal

    @Test("Maps a top-left display rect on a negative-origin screen")
    func mapsTopLeftSelectionToGlobalAppKitCoordinates() {
        let selection = ScreenshotSelection(
            displayID: 42,
            screenFrameInGlobalPoints: CGRect(x: -1_920, y: 120, width: 1_920, height: 1_080),
            sourceRectInDisplayPoints: CGRect(x: 100, y: 200, width: 300, height: 400),
            backingScaleFactor: 2,
            initialImage: NSImage(size: NSSize(width: 600, height: 800))
        )

        #expect(
            selection.globalFrameInScreenPoints ==
                CGRect(x: -1_820, y: 600, width: 300, height: 400)
        )
        #expect(selection.displayID == 42)
        #expect(selection.backingScaleFactor == 2)
    }

    @Test("Keeps the same height when the selected rect touches the screen top")
    func mapsSelectionAtScreenTop() {
        let selection = ScreenshotSelection(
            displayID: 7,
            screenFrameInGlobalPoints: CGRect(x: 300, y: -900, width: 1_600, height: 900),
            sourceRectInDisplayPoints: CGRect(x: 20, y: 0, width: 500, height: 180),
            backingScaleFactor: 1,
            initialImage: NSImage(size: NSSize(width: 500, height: 180))
        )

        #expect(
            selection.globalFrameInScreenPoints ==
                CGRect(x: 320, y: -180, width: 500, height: 180)
        )
    }

    @Test("A large initial image is sampled to the live capture pixel budget")
    func limitsLargeInitialImagePixels() throws {
        let logicalSize = NSSize(width: 1_500, height: 750)
        let sourceImage = try #require(
            makeImage(pixelWidth: 3_000, pixelHeight: 1_500, logicalSize: logicalSize)
        )
        let sourceRect = CGRect(x: 20, y: 30, width: 1_500, height: 750)

        let selection = ScreenshotSelection(
            displayID: 9,
            screenFrameInGlobalPoints: CGRect(x: 0, y: 0, width: 2_000, height: 1_200),
            sourceRectInDisplayPoints: sourceRect,
            backingScaleFactor: 2,
            initialImage: sourceImage
        )
        let sampledImage = try #require(selection.initialImage.toCGImage())

        #expect(sampledImage.width == InPlaceTranslationConstants.maximumCaptureLongEdge)
        #expect(sampledImage.height == 1_280)
        #expect(selection.initialImage.size == logicalSize)
        #expect(selection.sourceRectInDisplayPoints == sourceRect)
        #expect(selection.backingScaleFactor == 2)
    }

    @Test("A small initial image keeps its pixels and logical size")
    func preservesSmallInitialImage() throws {
        let logicalSize = NSSize(width: 400, height: 300)
        let sourceImage = try #require(
            makeImage(pixelWidth: 800, pixelHeight: 600, logicalSize: logicalSize)
        )

        let selection = ScreenshotSelection(
            displayID: 10,
            screenFrameInGlobalPoints: CGRect(x: 0, y: 0, width: 1_000, height: 800),
            sourceRectInDisplayPoints: CGRect(x: 0, y: 0, width: 400, height: 300),
            backingScaleFactor: 2,
            initialImage: sourceImage
        )
        let sampledImage = try #require(selection.initialImage.toCGImage())

        #expect(sampledImage.width == 800)
        #expect(sampledImage.height == 600)
        #expect(selection.initialImage.size == logicalSize)
    }

    // MARK: Private

    private func makeImage(
        pixelWidth: Int,
        pixelHeight: Int,
        logicalSize: NSSize
    )
        -> NSImage? {
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage()
        else {
            return nil
        }
        return NSImage(cgImage: image, size: logicalSize)
    }
}
