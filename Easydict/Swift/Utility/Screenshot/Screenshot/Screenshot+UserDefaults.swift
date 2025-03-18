//
//  Screenshot+UserDefaults.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/17.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - UserDefaults Properties

extension Screenshot {
    // MARK: - UserDefaults keys

    /// Has requested permission key
    private var hasRequestedPermissionKey: String {
        "easydict.screenshot.hasRequestedPermission"
    }

    /// Last screenshot rect key
    private var lastScreenshotRectKey: String {
        "easydict.screenshot.lastScreenshotRect"
    }

    /// Last screen key
    private var lastScreenKey: String {
        "easydict.screenshot.lastScreen"
    }

    /// Last screen frame key
    private var lastScreenFrameKey: String {
        "easydict.screenshot.lastScreenFrame"
    }

    /// Whether screen capture permission has been requested
    @objc public var hasRequestedPermission: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasRequestedPermissionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasRequestedPermissionKey)
        }
    }

    /// Last screenshot rectangle, persisted in UserDefaults
    @objc public var lastScreenshotRect: CGRect {
        get {
            let defaults = UserDefaults.standard
            guard let rectString = defaults.string(forKey: lastScreenshotRectKey) else {
                return .zero
            }
            return NSRectFromString(rectString)
        }
        set {
            let defaults = UserDefaults.standard
            let rectString = NSStringFromRect(newValue)
            defaults.set(rectString, forKey: lastScreenshotRectKey)
        }
    }

    @objc public var lastScreen: NSScreen? {
        get {
            let defaults = UserDefaults.standard
            guard let screenDescription = defaults.string(forKey: lastScreenKey) else {
                return nil
            }
            return NSScreen.screens.first { $0.deviceDescriptionString == screenDescription }
        }
        set {
            let defaults = UserDefaults.standard
            let screenDescription = newValue?.deviceDescriptionString
            NSLog("lastScreen screenDescription: \(screenDescription ?? "")")
            defaults.set(screenDescription, forKey: lastScreenKey)
        }
    }

    @objc public var lastScreenFrame: NSRect {
        get {
            let defaults = UserDefaults.standard
            guard let frameString = defaults.string(forKey: lastScreenFrameKey) else {
                return .zero
            }
            return NSRectFromString(frameString)
        }
        set {
            let defaults = UserDefaults.standard
            let frameString = NSStringFromRect(newValue)
            defaults.set(frameString, forKey: lastScreenFrameKey)
        }
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
