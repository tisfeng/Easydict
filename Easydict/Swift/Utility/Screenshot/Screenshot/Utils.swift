//
//  Screencapture.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

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
/// - Parameter screen: The screen to capture.
/// - Parameter rect: The rect in the target screen to capture. The rect is `top-left` origin. If nil, capture the entire screen.
/// - Returns: NSImage of captured screenshot or nil if failed
func takeScreenshot(screen: NSScreen, rect: CGRect? = nil) -> NSImage? {
    let rect = rect ?? screen.bounds
    NSLog("Taking screenshot of rect: \(rect), screen: \(screen.debugDescription)")

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

/// Convert `bottom-left` origin rect to `top-left` origin rect
/// - Parameter rect: `bottom-left` origin rect
/// - Parameter screenFrame: Screen frame is `bottom-left` origin.
/// - Returns: `top-left` origin rect
func convertToTopLeftOrigin(rect: CGRect, in screenFrame: CGRect? = nil) -> CGRect {
    let screenHeight = screenFrame?.height ?? rect.height
    let originY = screenHeight - rect.height
    return CGRect(x: rect.minX, y: originY, width: rect.width, height: rect.height)
}

/// Adjust last screenshot rect to fit within the current screen boundaries
/// - Parameters: lastRect Last screenshot rect, `top-left` origin
/// - Parameters: lastScreenFrame: Screen where the last screenshot was taken, `bottom-left` origin
/// - Parameters: currentScreenFrame: Screen where the current screenshot is being taken, `bottom-left` origin
/// - Returns: Adjusted rect that fits within the current screen, `top-left` origin
/// - Note: If `currentScreen` contains `lastRect`, the adjusted rect will be the same as lastRect.
///        Otherwise, if `lastRect` size is larger than `currentScreen`, the adjusted rect will be scaled down to fit within the screen.
///        Else, the adjusted rect location will be scaled to fit within the screen.
public func adjusLastScreenshotRect(
    lastRect: CGRect,
    lastScreenFrame: CGRect,
    currentScreenFrame: CGRect
)
    -> CGRect {
    NSLog("Adjusting last screenshot rect: \(lastRect)")
    NSLog("Last screen frame: \(lastScreenFrame)")
    NSLog("Current screen frame: \(currentScreenFrame)")

    // Convert lastRect from top-left to bottom-left origin for comparison with screen frames
    let lastRectScreenCoordinate = CGRect(
        x: lastRect.origin.x,
        y: lastScreenFrame.height - lastRect.origin.y - lastRect.height,
        width: lastRect.width,
        height: lastRect.height
    )
    NSLog("Last rect screen coordinate: \(lastRectScreenCoordinate)")

    // Check if the last rect is completely within current screen's bounds
    if currentScreenFrame.contains(lastRectScreenCoordinate) {
        NSLog("Last rect is within the current screen")
        return lastRect
    }

    // If lastRect size is larger than current screen, scale down to fit within the screen
    if lastRect.width > currentScreenFrame.width || lastRect.height > currentScreenFrame.height {
        NSLog("Last rect is larger than current screen, scaling down")

        let widthRatio = currentScreenFrame.width / lastRect.width
        let heightRatio = currentScreenFrame.height / lastRect.height
        let scale = min(widthRatio, heightRatio) * 0.9 // Use 90% of screen to leave margin

        let newSize = CGSize(
            width: lastRect.width * scale,
            height: lastRect.height * scale
        )

        // Center in current screen (in top-left coordinates)
        let newX = (currentScreenFrame.width - newSize.width) / 2
        let newY = (currentScreenFrame.height - newSize.height) / 2

        // This is already in top-left coordinates for screen usage
        return CGRect(
            x: newX,
            y: newY,
            width: newSize.width,
            height: newSize.height
        )
    }

    // Calculate relative position ratio in the original screen
    let xRatio = (lastRectScreenCoordinate.origin.x - lastScreenFrame.origin.x) / lastScreenFrame.width
    let yRatio = (lastRectScreenCoordinate.origin.y - lastScreenFrame.origin.y) / lastScreenFrame.height

    // Apply that ratio to the new screen (still in bottom-left coordinates)
    let newX = currentScreenFrame.origin.x + (xRatio * currentScreenFrame.width)
    let newY = currentScreenFrame.origin.y + (yRatio * currentScreenFrame.height)

    // Convert back to top-left origin coordinates for the result
    // For top-left coordinates, we need to reverse the y-axis again
    let topLeftY = currentScreenFrame.height - (newY - currentScreenFrame.origin.y) - lastRect.height

    // Create the final result in top-left coordinates
    let adjustedRect = CGRect(
        x: newX - currentScreenFrame.origin.x,
        y: topLeftY,
        width: lastRect.width,
        height: lastRect.height
    ).integral

    NSLog("Adjusted rect (top-left): \(adjustedRect)")
    return adjustedRect
}

/// Adjust last screenshot rect to fit within the current screen boundaries
/// - Parameters: lastRect Last screenshot rect, `top-left` origin
/// - Parameters: currentScreenFrame: Screen where the current screenshot is being taken, `bottom-left` origin
/// - Returns: Adjusted rect that fits within the current screen, `top-left` origin
/// - Note: If `currentScreen` contains `lastRect`, the adjusted rect will be the same as lastRect.
///        Otherwise, if `lastRect` size is larger than `currentScreen`, the adjusted rect will be scaled down to fit within the screen.
///        Else, the adjusted rect location to fit within the screen.
public func adjusLastScreenshotRect(
    lastRect: CGRect,
    screenFrame: CGRect
)
    -> CGRect {
    NSLog("Adjusting last screenshot rect: \(lastRect)")
    NSLog("Current screen frame: \(screenFrame)")

    if lastRect.isEmpty {
        NSLog("Last rect is empty, cannot adjust")
        return .zero
    }

    // Convert lastRect from top-left to bottom-left origin for comparison with screen frames
    let lastRectScreenCoordinate = CGRect(
        x: lastRect.origin.x,
        y: screenFrame.height - lastRect.origin.y - lastRect.height,
        width: lastRect.width,
        height: lastRect.height
    )

    // Check if the last rect is completely within current screen's bounds
    let currentScreenBounds = CGRect(origin: .zero, size: screenFrame.size)
    if currentScreenBounds.contains(lastRectScreenCoordinate) {
        NSLog("Last rect is within the current screen")
        return lastRect
    }

    // If lastRect size is larger than current screen, scale down to fit within the screen
    if lastRect.width > screenFrame.width || lastRect.height > screenFrame.height {
        NSLog("Last rect is larger than current screen, scaling down")

        let widthRatio = screenFrame.width / lastRect.width
        let heightRatio = screenFrame.height / lastRect.height
        let scale = min(widthRatio, heightRatio) * 0.9 // Use 90% of screen to leave margin

        let newSize = CGSize(
            width: lastRect.width * scale,
            height: lastRect.height * scale
        )

        // Center in current screen (in top-left coordinates)
        let newX = (screenFrame.width - newSize.width) / 2
        let newY = (screenFrame.height - newSize.height) / 2

        return CGRect(
            x: newX,
            y: newY,
            width: newSize.width,
            height: newSize.height
        )
    }

    // Adjust position to fit within screen
    NSLog("Adjusting last rect position to fit within screen")
    var adjustedRect = lastRect

    // Adjust X position
    if adjustedRect.minX < 0 {
        adjustedRect.origin.x = 0
    } else if adjustedRect.maxX > screenFrame.width {
        adjustedRect.origin.x = screenFrame.width - adjustedRect.width
    }

    // Adjust Y position
    if adjustedRect.minY < 0 {
        adjustedRect.origin.y = 0
    } else if adjustedRect.maxY > screenFrame.height {
        adjustedRect.origin.y = screenFrame.height - adjustedRect.height
    }

    NSLog("Adjusted rect (top-left): \(adjustedRect)")
    return adjustedRect.integral
}

/// Get the current mouse screen
func getCurrentMouseScreen() -> NSScreen? {
    NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
}
