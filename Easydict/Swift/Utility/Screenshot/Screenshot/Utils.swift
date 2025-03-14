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

/// Convert `bottom-left` origin rect to `top-left` origin rect
/// - Parameter rect: `bottom-left` origin rect
/// - Parameter screenFrame: Screen frame is `bottom-left` origin.
/// - Returns: `top-left` origin rect
func convertToTopLeftOrigin(rect: CGRect, in screenFrame: CGRect? = nil) -> CGRect {
    let screenHeight = screenFrame?.height ?? rect.height
    let originY = screenHeight - rect.height
    return CGRect(x: rect.minX, y: originY, width: rect.width, height: rect.height)
}

private func takeScreenshot(of area: CGRect) -> NSImage? {
    NSLog("Take screenshot of area: \(area)")

    // 获取所有显示器信息
    var displayCount: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &displayCount) == .success else {
        return nil
    }

    let displays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(displayCount))
    defer { displays.deallocate() }

    guard CGGetActiveDisplayList(displayCount, displays, &displayCount) == .success else {
        return nil
    }

    // 找到完全包含截图区域的显示器
    var targetDisplayID = CGMainDisplayID()
    var displayBounds = CGRect.zero
    var displayScaling: CGFloat = 1.0

    // 优先查找完全包含区域的显示器
    for i in 0 ..< Int(displayCount) {
        let display = displays[i]
        let bounds = CGDisplayBounds(display)

        // 精确判断：截图区域必须完全在显示器范围内
        if bounds.contains(area) {
            targetDisplayID = display
            displayBounds = bounds
            if let mode = CGDisplayCopyDisplayMode(display) {
                displayScaling = CGFloat(mode.pixelWidth) / CGFloat(mode.width)
            }
            break
        }
    }

    // 如果没找到完全包含的显示器，使用区域中心点所在显示器
    if displayBounds == .zero {
        let areaCenter = CGPoint(x: area.midX, y: area.midY)
        for i in 0 ..< Int(displayCount) {
            let display = displays[i]
            let bounds = CGDisplayBounds(display)
            if bounds.contains(areaCenter) {
                targetDisplayID = display
                displayBounds = bounds
                if let mode = CGDisplayCopyDisplayMode(display) {
                    displayScaling = CGFloat(mode.pixelWidth) / CGFloat(mode.width)
                }
                break
            }
        }
    }

    // 最终确保截图区域不越界
    let clippedArea = area.intersection(displayBounds)
    guard !clippedArea.isEmpty else {
        NSLog("Clipped area is empty")
        return nil
    }

    // 转换为目标显示器本地坐标系（考虑Retina缩放）
    let localOrigin = CGPoint(
        x: (clippedArea.origin.x - displayBounds.origin.x) * displayScaling,
        y: (displayBounds.maxY - clippedArea.maxY) * displayScaling // 修正Y轴坐标计算
    )
    let localSize = CGSize(
        width: clippedArea.width * displayScaling,
        height: clippedArea.height * displayScaling
    )
    let localRect = CGRect(origin: localOrigin, size: localSize)

    NSLog(
        "Final capture: displayID=\(targetDisplayID), displayBounds=\(displayBounds), localRect=\(localRect)"
    )

    guard let cgImage = CGDisplayCreateImage(targetDisplayID, rect: localRect) else {
        return nil
    }

    // 根据缩放比例计算最终图像尺寸
    let finalSize = NSSize(
        width: CGFloat(cgImage.width) / displayScaling,
        height: CGFloat(cgImage.height) / displayScaling
    )
    NSLog("Final image size: \(finalSize)")

    return NSImage(cgImage: cgImage, size: finalSize)
}
