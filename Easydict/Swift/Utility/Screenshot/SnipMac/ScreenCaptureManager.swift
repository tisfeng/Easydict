//
//  ScreenCaptureManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

enum ScreenCaptureManager {
    // MARK: Internal

    static func takeScreenshot(of area: CGRect? = nil) -> NSImage? {
        var capturedImage: NSImage?
        let semaphore = DispatchSemaphore(value: 0)

        checkScreenCapturePermission {
            let captureRect = area ?? CGDisplayBounds(CGMainDisplayID())

            // 使用 CGDisplayCreateImage 获取不包含光标的截图
            if let cgImage = CGDisplayCreateImage(CGMainDisplayID(), rect: captureRect) {
                capturedImage = NSImage(
                    cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)
                )
            } else {
                // 备选方案：使用 CGWindowListCreateImage
                guard let imageRef = CGWindowListCreateImage(
                    captureRect,
                    .optionOnScreenOnly,
                    kCGNullWindowID,
                    .bestResolution
                )
                else {
                    print("Unable to capture the screen")
                    semaphore.signal()
                    return
                }

                capturedImage = NSImage(
                    cgImage: imageRef, size: NSSize(width: imageRef.width, height: imageRef.height)
                )
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)
        return capturedImage
    }

    // MARK: Private

    private static func checkScreenCapturePermission(completion: @escaping () -> ()) {
        let displayID = CGMainDisplayID()
        let screenFrame = CGDisplayBounds(displayID)
        let dummyImage = CGWindowListCreateImage(
            screenFrame, .optionOnScreenOnly, kCGNullWindowID, .bestResolution
        )

        if dummyImage != nil {
            completion()
        } else {
            print("Screen capture permission not granted.")
        }
    }
}
