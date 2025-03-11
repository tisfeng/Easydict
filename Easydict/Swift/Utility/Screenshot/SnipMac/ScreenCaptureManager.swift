//
//  ScreenCaptureManager.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/10/23.
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

            guard let imageRef = CGWindowListCreateImage(
                captureRect,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            ) else {
                print("Unable to capture the screen")
                semaphore.signal()
                return
            }

            capturedImage = NSImage(cgImage: imageRef, size: NSSize(width: imageRef.width, height: imageRef.height))
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)
        return capturedImage
    }

    static func saveScreenshot(data: Data) {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "SnipMacScreenRecording \(timestamp).png"
        let fileURL = desktopURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            print("Screenshot saved to: \(fileURL.path())")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }

    // MARK: Private

    private static func checkScreenCapturePermission(completion: @escaping () -> ()) {
        let displayID = CGMainDisplayID()
        let screenFrame = CGDisplayBounds(displayID)
        let dummyImage = CGWindowListCreateImage(screenFrame, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)

        if dummyImage != nil {
            completion()
        } else {
            print("Screen capture permission not granted.")
        }
    }
}
