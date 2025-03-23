//
//  NSScreen+Extention.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/20.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension NSScreen {
    /// Take screenshot of the specified area in the screen.
    /// - Parameter rect: The rect in the screen to capture. The rect is `top-left` origin. If nil, capture the entire screen.
    /// - Returns: NSImage of captured screenshot or nil if failed
    func takeScreenshot(rect: CGRect? = nil) -> NSImage? {
        let rect = rect ?? bounds
        NSLog("Taking screenshot of rect: \(rect), screen: \(debugDescription)")

        // Get screen's display ID
        let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
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
        let scaleFactor = backingScaleFactor
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

    var bounds: CGRect {
        CGRect(origin: .zero, size: frame.size)
    }

    /// Adjust last screenshot rect to fit within the current screen bounds
    /// - Parameters: lastRect Last screenshot rect, `top-left` origin
    /// - Parameters: currentScreenFrame: Screen where the current screenshot is being taken, `bottom-left` origin
    /// - Returns: Adjusted rect that fits within the current screen, `top-left` origin
    /// - Note: If `currentScreen` contains `lastRect`, the adjusted rect will be the same as lastRect.
    ///        Otherwise, if `lastRect` size is larger than `currentScreen`, the adjusted rect will be scaled down to fit within the screen.
    ///        Else, the adjusted rect location to fit within the screen.
    func adjustedScreenshotRect(_ lastRect: CGRect) -> CGRect {
        NSLog("Adjusting last screenshot rect: \(lastRect)")

        let screenFrame = frame
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
    class func currentMouseScreen() -> NSScreen? {
        screens.first { $0.frame.contains(NSEvent.mouseLocation) }
    }
}

extension NSScreen {
    /// Device description string
    var deviceDescriptionString: String {
        // Sort keys to ensure consistent order
        let sortedKeys = deviceDescription.keys.sorted { $0.rawValue < $1.rawValue }

        var description = ""
        for key in sortedKeys {
            if let value = deviceDescription[key] {
                description += "\(key.rawValue): \(value)\n"
            }
        }
        return "{\n\(description)}"
    }

    func isSameScreen(_ other: NSScreen?) -> Bool {
        deviceDescriptionString == other?.deviceDescriptionString
    }
}
