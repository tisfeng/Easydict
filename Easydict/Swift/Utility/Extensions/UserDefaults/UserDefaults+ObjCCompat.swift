//
//  UserDefaults+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension UserDefaults {
    /// Reads a string from UserDefaults. If not exist, returns defaultValue and writes it.
    ///
    /// - Parameters:
    ///   - key: The key to read.
    ///   - defaultValue: The default value if key doesn't exist.
    /// - Returns: The string value.
    @objc(mm_readString:defaultValue:)
    static func string(forKey key: String, defaultValue: String) -> String {
        readValue(
            forKey: key,
            defaultValue: defaultValue,
            checkClass: NSString.self
        ) as? String ?? defaultValue
    }

    /// Reads an integer from UserDefaults. If not exist, returns defaultValue and writes it.
    ///
    /// - Parameters:
    ///   - key: The key to read.
    ///   - defaultValue: The default value if key doesn't exist.
    /// - Returns: The integer value.
    @objc(mm_readInteger:defaultValue:)
    static func integer(forKey key: String, defaultValue: Int) -> Int {
        let value = readValue(
            forKey: key,
            defaultValue: NSNumber(value: defaultValue),
            checkClass: NSNumber.self
        ) as? NSNumber
        return value?.intValue ?? defaultValue
    }

    /// Reads a boolean from UserDefaults. If not exist, returns defaultValue and writes it.
    ///
    /// - Parameters:
    ///   - key: The key to read.
    ///   - defaultValue: The default value if key doesn't exist.
    /// - Returns: The boolean value.
    @objc(mm_readBool:defaultValue:)
    static func bool(forKey key: String, defaultValue: Bool) -> Bool {
        let value = readValue(
            forKey: key,
            defaultValue: NSNumber(value: defaultValue),
            checkClass: NSNumber.self
        ) as? NSNumber
        return value?.boolValue ?? defaultValue
    }

    /// Reads a value from UserDefaults for the given key.
    ///
    /// - Parameter key: The key to read.
    /// - Returns: The value or nil if not found.
    @objc(mm_read:)
    static func readValue(forKey key: String) -> Any? {
        standard.object(forKey: key)
    }

    /// Reads a value from UserDefaults with default value and class check.
    ///
    /// - Parameters:
    ///   - key: The key to read.
    ///   - defaultValue: The default value if key doesn't exist or type mismatch.
    ///   - checkClass: The expected class to validate.
    /// - Returns: The value.
    @objc(mm_read:defaultValue:checkClass:)
    static func readValue(forKey key: String, defaultValue: Any?, checkClass: AnyClass) -> Any? {
        guard let value = standard.object(forKey: key) else {
            writeValue(defaultValue, forKey: key)
            return defaultValue
        }

        if let value = value as? NSObject, value.isKind(of: checkClass) {
            return value
        } else {
            writeValue(defaultValue, forKey: key)
            return defaultValue
        }
    }

    /// Writes a value to UserDefaults for the given key.
    ///
    /// - Parameters:
    ///   - value: The value to write.
    ///   - key: The key to associate with the value.
    @objc(mm_write:forKey:)
    static func writeValue(_ value: Any?, forKey key: String) {
        standard.set(value, forKey: key)
    }
}
