//
//  Color+Hex.swift
//  Easydict
//
//  Created by Easydict on 2025/11/25.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI

// MARK: - SwiftUI Color Extension

extension Color {
    /// Initialize Color from hex string.
    ///
    /// Supports various formats:
    /// - `#RGB` (12-bit)
    /// - `#RRGGBB` (24-bit)
    /// - `#AARRGGBB` (32-bit with alpha)
    /// - `RGB`, `RRGGBB`, `AARRGGBB` (without #)
    ///
    /// - Parameters:
    ///   - hex: Hex string (e.g., "#FF5733", "FF5733", "#F57")
    ///   - alpha: Optional alpha override (0.0 to 1.0). If not specified, uses alpha from hex string or defaults to 1.0.
    ///
    /// - Example:
    /// ```swift
    /// let red = Color(hex: "#FF0000")
    /// let blue = Color(hex: "0000FF")
    /// let greenTransparent = Color(hex: "#00FF00", alpha: 0.5)
    /// ```
    init(hex: String, alpha: CGFloat? = nil) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255) // Default to white for invalid format
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: alpha ?? Double(a) / 255.0
        )
    }

    /// Initialize Color from RGB integer values (0-255).
    ///
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    ///   - alpha: Alpha component (0.0-1.0), defaults to 1.0
    ///
    /// - Example:
    /// ```swift
    /// let purple = Color(r: 128, g: 0, b: 255)
    /// let semiTransparent = Color(r: 255, g: 100, g: 50, alpha: 0.7)
    /// ```
    init(r: Int, g: Int, b: Int, alpha: CGFloat = 1.0) {
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(alpha)
        )
    }

    /// Generate a random light color.
    ///
    /// RGB values are between 60-100% to ensure the color is light/pastel.
    ///
    /// - Returns: A random light color
    ///
    /// - Example:
    /// ```swift
    /// let randomColor = Color.random
    /// ```
    static var random: Color {
        // Generate values between 0.6-1.0 to ensure light colors
        let start = 60
        let length = 40
        let r = CGFloat(start + Int.random(in: 0 ..< length)) / 100.0
        let g = CGFloat(start + Int.random(in: 0 ..< length)) / 100.0
        let b = CGFloat(start + Int.random(in: 0 ..< length)) / 100.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    /// Convert Color to hex string.
    ///
    /// - Returns: Hex string in format `#RRGGBB`, or nil if conversion fails
    ///
    /// - Example:
    /// ```swift
    /// let color = Color.red
    /// print(color.hexString) // "#FF0000"
    /// ```
    var hexString: String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - NSColor Extension (AppKit Compatibility)

@objc
extension NSColor {
    /// Initialize NSColor from hex string (modern API).
    ///
    /// - Parameters:
    ///   - hexString: Hex string (e.g., "#FF5733" or "FF5733")
    ///   - alpha: Alpha component (0.0-1.0), defaults to 1.0
    ///
    /// - Returns: NSColor instance
    static func color(withHexString hexString: String, alpha: CGFloat = 1.0) -> NSColor {
        NSColor(Color(hex: hexString, alpha: alpha))
    }

    /// Initialize NSColor from hex string (legacy mm_ API for Objective-C compatibility).
    ///
    /// - Parameter hexStr: Hex string (e.g., "#FF5733" or "FF5733")
    /// - Returns: NSColor instance
    @objc(mm_colorWithHexString:)
    static func mm_color(withHexString hexStr: String) -> NSColor {
        color(withHexString: hexStr, alpha: 1.0)
    }

    /// Initialize NSColor from hex string with alpha (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - hexStr: Hex string
    ///   - alpha: Alpha component (0.0-1.0)
    /// - Returns: NSColor instance
    @objc(mm_colorWithHexString:alpha:)
    static func mm_color(withHexString hexStr: String, alpha: CGFloat) -> NSColor {
        color(withHexString: hexStr, alpha: alpha)
    }

    /// Initialize NSColor from RGB integer values (modern API).
    ///
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    ///   - alpha: Alpha component (0.0-1.0), defaults to 1.0
    ///
    /// - Returns: NSColor instance
    static func color(withR r: Int, g: Int, b: Int, alpha: CGFloat = 1.0) -> NSColor {
        NSColor(Color(r: r, g: g, b: b, alpha: alpha))
    }

    /// Initialize NSColor from RGB integer values (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    /// - Returns: NSColor instance
    @objc(mm_colorWithIntR:g:b:)
    static func mm_color(withIntR r: Int, g: Int, b: Int) -> NSColor {
        color(withR: r, g: g, b: b, alpha: 1.0)
    }

    /// Initialize NSColor from RGB integer values with alpha (legacy mm_ API).
    ///
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    ///   - alpha: Alpha component (0.0-1.0)
    /// - Returns: NSColor instance
    @objc(mm_colorWithIntR:g:b:alhpa:)
    static func mm_color(withIntR r: Int, g: Int, b: Int, alhpa alpha: CGFloat) -> NSColor {
        color(withR: r, g: g, b: b, alpha: alpha)
    }

    /// Generate a random light NSColor (modern API).
    ///
    /// - Returns: A random light color
    static func randomColor() -> NSColor {
        NSColor(Color.random)
    }

    /// Generate a random light NSColor (legacy mm_ API).
    ///
    /// - Returns: A random light color
    @objc(mm_randomColor)
    static func mm_randomColor() -> NSColor {
        randomColor()
    }

    /// Convert NSColor to hex string (modern API).
    ///
    /// - Returns: Hex string in format `#RRGGBB`, or nil if conversion fails
    var hexString: String? {
        Color(self).hexString
    }

    /// Convert NSColor to hex string (legacy mm_ API).
    ///
    /// - Parameter color: NSColor to convert
    /// - Returns: Hex string in format `#RRGGBB`
    @objc(mm_hexStringFromColor:)
    static func mm_hexString(from color: NSColor) -> String {
        color.hexString ?? "#FFFFFF"
    }
}
