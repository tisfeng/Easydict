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
        startScreenshot(of: nil, completion: completion)
    }

    @objc
    public func takeScreenshot(of area: CGRect, completion: @escaping (NSImage?) -> ()) {
        startScreenshot(of: area, completion: completion)
    }

    // MARK: Internal

    @objc static let shared = Screencapture()

    // MARK: Private

    private func startScreenshot(of area: CGRect? = nil, completion: @escaping (NSImage?) -> ()) {
        let fileManager = FileManager.default
        let temporaryPath = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
            .path

        let process = Process()
        process.launchPath = "/usr/sbin/screencapture"

        if let area = area {
            NSLog("Start screenshot of area: \(area)")
            let areaString =
                "\(Int(area.origin.x)),\(Int(area.origin.y)),\(Int(area.width)),\(Int(area.height))"
            process.arguments = ["-x", "-R", areaString, temporaryPath]
        } else {
            process.arguments = ["-i", "-s", "-x", temporaryPath]
        }

        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                if fileManager.fileExists(atPath: temporaryPath) {
                    if let image = NSImage(contentsOfFile: temporaryPath) {
                        completion(image)
                        try? fileManager.removeItem(atPath: temporaryPath)
                    } else {
                        NSLog("Failed to load screenshot from \(temporaryPath)")
                        completion(nil)
                    }
                } else {
                    NSLog(area == nil ? "Screenshot was cancelled" : "Area screenshot capture failed")
                    completion(nil)
                }
            }
        }

        do {
            try process.run()
        } catch {
            NSLog("Failed to launch screencapture: \(error)")
            completion(nil)
        }
    }
}
