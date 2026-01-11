//
//  RectHelper.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - RectHelper

enum RectHelper {
    /// Returns a rect from two points with a minimum expanded radius fallback.
    static func frame(from startPoint: CGPoint, to endPoint: CGPoint, expandedRadius: CGFloat) -> CGRect {
        var x = min(startPoint.x, endPoint.x)
        if x == endPoint.x {
            x = endPoint.x - expandedRadius
        }

        var y = min(startPoint.y, endPoint.y)
        if y == endPoint.y {
            y = endPoint.y - expandedRadius
        }

        var width = abs(startPoint.x - endPoint.x)
        if width == 0 {
            width = expandedRadius * 2
        }

        var height = abs(startPoint.y - endPoint.y)
        if height == 0 {
            height = expandedRadius * 2
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
