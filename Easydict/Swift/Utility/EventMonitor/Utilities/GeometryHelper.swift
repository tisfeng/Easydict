//
//  GeometryHelper.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - GeometryHelper

enum GeometryHelper {
    /// Checks whether a point lies inside a circle.
    static func isPoint(_ point: CGPoint, insideCircleWithCenter center: CGPoint, radius: CGFloat) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distanceSquared = dx * dx + dy * dy
        let radiusSquared = radius * radius
        return distanceSquared <= radiusSquared
    }
}
