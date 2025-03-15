//
//  Screencapture.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation
import QuartzCore

func calculateCropRect(from selectedRect: CGRect) -> CGRect {
    guard let screen = getActiveScreen() else { return CGRect.zero }
    let scaleFactor = screen.backingScaleFactor

    let flippedRect = CGRect(
        x: selectedRect.origin.x,
        y: screen.frame.height - selectedRect.origin.y - selectedRect.height,
        width: selectedRect.width,
        height: selectedRect.height
    )

    let scaledRect = CGRect(
        x: flippedRect.origin.x * scaleFactor,
        y: flippedRect.origin.y * scaleFactor,
        width: flippedRect.width * scaleFactor,
        height: flippedRect.height * scaleFactor
    )

    return scaledRect
}

/// Get the screen that contains the current mouse location
/// - Returns: Screen frame is `bottom-left` origin.
func getActiveScreenFrame() -> CGRect {
    let activeScreen = getActiveScreen() ?? NSScreen.main
    return activeScreen?.frame ?? .zero
}

/// Get active screen.
func getActiveScreen() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    let screens = NSScreen.screens
    for screen in screens {
        let screenFrame = screen.frame
        if screenFrame.contains(mouseLocation) {
            return screen
        }
    }
    return NSScreen.main
}

/// Take screenshot of the specified area in the target screen.
/// - Parameter rect: The rect in the target screen to capture. The rect's origin is `top-left` origin.
/// - Parameter targetScreen: The screen to capture. If nil, the active screen will be used.
/// - Returns: NSImage of captured screenshot or nil if failed
func takeScreenshot(of rect: CGRect, targetScreen: NSScreen? = nil) -> NSImage? {
    NSLog("Taking screenshot of rect: \(rect)")

    let screen = targetScreen ?? getActiveScreen()
    guard let screen = screen else {
        NSLog("No screen found")
        return nil
    }

    // Get screen's display ID
    let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
    guard let displayID = screenNumber?.uint32Value else {
        NSLog("Failed to get display ID for screen")
        return nil
    }

    // Create a screenshot of the entire display
    guard let displayImage = CGDisplayCreateImage(displayID) else {
        NSLog("Failed to create display image")
        return nil
    }

    // Apply screen scale factor for Retina displays
    let scaleFactor = screen.backingScaleFactor
    let scaledCropRect = CGRect(
        x: rect.origin.x * scaleFactor,
        y: rect.origin.y * scaleFactor,
        width: rect.width * scaleFactor,
        height: rect.height * scaleFactor
    ).integral

    // Crop the image to the specified rect
    guard let croppedImage = displayImage.cropping(to: scaledCropRect) else {
        NSLog("Failed to crop display image")
        return nil
    }

    let image = NSImage(cgImage: croppedImage, size: .zero)

    return image
}

/// Convert rect to screen coordinate system
/// - Parameter rect: `top-left` origin rect
/// - Parameter screenFrame: Screen frame is `bottom-left` origin.
/// - Returns: `bottom-left` origin rect
func convertToScreenCoordinate(rect: CGRect, in screenFrame: CGRect? = nil) -> CGRect {
    let screenFrame = screenFrame ?? getActiveScreenFrame()
    let globalRect = CGRect(
        x: screenFrame.origin.x + rect.origin.x,
        y: screenFrame.origin.y + screenFrame.height - rect.origin.y,
        width: rect.width,
        height: rect.height
    )
    return globalRect
}

/// Get bounds of the rect.
func getBounds(of rect: CGRect) -> CGRect {
    CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
}

/// Convert `bottom-left` origin rect to `top-left` origin rect
/// - Parameter rect: `bottom-left` origin rect
/// - Parameter screenFrame: Screen frame is `bottom-left` origin.
/// - Returns: `top-left` origin rect
func convertToTopLeftOrigin(rect: CGRect, in screenFrame: CGRect? = nil) -> CGRect {
    let screenHeight = screenFrame?.height ?? rect.height
    let originY = screenHeight - rect.height
    return CGRect(x: rect.minX, y: originY, width: rect.width, height: rect.height)
}
