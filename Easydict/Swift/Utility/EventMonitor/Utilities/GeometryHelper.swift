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
        let distanceSquared = pow(point.x - center.x, 2) + pow(point.y - center.y, 2)
        let radiusSquared = pow(radius, 2)
        return distanceSquared <= radiusSquared
    }
}
