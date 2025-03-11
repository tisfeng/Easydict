//
//  Screencapture.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/9.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Cocoa

// MARK: - Screencapture

@objc
public class Screencapture: NSObject {
    /// Start the screenshot process using macOS native screencapture tool
    @objc
    public func captureScreenshot(completion: @escaping (NSImage?) -> ()) {
        let fileManager = FileManager.default

        // Create a temporary file to store the screenshot
        let temporaryPath = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
            .path

        // Create a Process to run the screencapture command
        let process = Process()
        process.launchPath = "/usr/sbin/screencapture"

        // Set arguments for the screencapture command https://www.unix.com/man_page/osx/1/screencapture/
        // -i: interactive mode, allows user to select an area
        // -s: only allow mouse selection mode
        // -x: do not play sounds
        process.arguments = ["-i", "-s", "-o", temporaryPath]

        // Set process termination handler
        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                // Check if the file exists (if the user didn't cancel)
                if fileManager.fileExists(atPath: temporaryPath) {
                    // Load the image from the temporary file
                    if let image = NSImage(contentsOfFile: temporaryPath) {
                        completion(image)
                        // Delete the temporary file
                        try? fileManager.removeItem(atPath: temporaryPath)
                    } else {
                        // Failed to load the image
                        NSLog("Failed to load screenshot from \(temporaryPath)")
                        completion(nil)
                    }
                } else {
                    // File doesn't exist, user probably cancelled
                    NSLog("Screenshot was cancelled")
                    completion(nil)
                }
            }
        }

        // Launch the process
        do {
            try process.run()
        } catch {
            NSLog("Failed to launch screencapture: \(error)")
            completion(nil)
        }
    }
}
