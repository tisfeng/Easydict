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
    // MARK: Public

    /// Take a screenshot interactively, using the system screencapture command.
    @objc
    public func takeScreenshot(completion: @escaping (NSImage?) -> ()) {
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
        process.arguments = ["-i", "-s", "-x", temporaryPath]

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

    // MARK: Internal

    @objc static let shared = Screencapture()

    /// Take a screenshot of a specific area, top-left origin.
    @objc
    func takeScreenshot(of area: CGRect, completion: @escaping (NSImage?) -> ()) {
        NSLog("Taking screenshot of area: \(area)")

        let fileManager = FileManager.default

        let temporaryPath = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
            .path

        let process = Process()
        process.launchPath = "/usr/sbin/screencapture"

        // Capture rectangle using format x,y,width,height (Top-Left origin)
        let areaString =
            "\(Int(area.origin.x)),\(Int(area.origin.y)),\(Int(area.width)),\(Int(area.height))"
        process.arguments = ["-x", "-R", areaString, temporaryPath]

        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                if fileManager.fileExists(atPath: temporaryPath) {
                    if let image = NSImage(contentsOfFile: temporaryPath) {
                        completion(image)
                        try? fileManager.removeItem(atPath: temporaryPath)
                    } else {
                        NSLog("Failed to load area screenshot from \(temporaryPath)")
                        completion(nil)
                    }
                } else {
                    NSLog("Area screenshot capture failed")
                    completion(nil)
                }
            }
        }

        do {
            try process.run()
        } catch {
            NSLog("Failed to launch area screencapture: \(error)")
            completion(nil)
        }
    }
}
