//
//  NSWindow+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSWindow {
    /// The x coordinate of the window's frame origin.
    @objc var x: CGFloat {
        get { frame.origin.x }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The y coordinate of the window's frame origin.
    @objc var y: CGFloat {
        get { frame.origin.y }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The width of the window's frame.
    @objc var width: CGFloat {
        get { frame.size.width }
        set {
            var newFrame = frame
            newFrame.size.width = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The height of the window's frame.
    @objc var height: CGFloat {
        get { frame.size.height }
        set {
            var newFrame = frame
            newFrame.size.height = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The top edge position of the window.
    @objc var top: CGFloat {
        get { frame.origin.y + frame.size.height }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue - frame.size.height
            setFrame(newFrame, display: true)
        }
    }

    /// The left edge position of the window.
    @objc var left: CGFloat {
        get { frame.origin.x }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The bottom edge position of the window.
    @objc var bottom: CGFloat {
        get { frame.origin.y }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The right edge position of the window.
    @objc var right: CGFloat {
        get { frame.origin.x + frame.size.width }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue - frame.size.width
            setFrame(newFrame, display: true)
        }
    }

    /// The x coordinate of the window's center point.
    @objc var centerX: CGFloat {
        get { frame.midX }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue - frame.size.width * 0.5
            setFrame(newFrame, display: true)
        }
    }

    /// The y coordinate of the window's center point.
    @objc var centerY: CGFloat {
        get { frame.midY }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue - frame.size.height * 0.5
            setFrame(newFrame, display: true)
        }
    }

    /// The origin point of the window's frame.
    @objc var origin: CGPoint {
        get { frame.origin }
        set {
            var newFrame = frame
            newFrame.origin = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The size of the window's frame.
    @objc var size: CGSize {
        get { frame.size }
        set {
            var newFrame = frame
            newFrame.size = newValue
            setFrame(newFrame, display: true)
        }
    }

    /// The center point of the window.
    /// Note: named centerPoint to avoid conflict with NSWindow's center() method.
    @objc var centerPoint: CGPoint {
        get { CGPoint(x: frame.midX, y: frame.midY) }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x - frame.size.width * 0.5
            newFrame.origin.y = newValue.y - frame.size.height * 0.5
            setFrame(newFrame, display: true)
        }
    }

    /// The top-left corner point of the window.
    @objc var topLeft: CGPoint {
        get { CGPoint(x: frame.origin.x, y: frame.origin.y + frame.size.height) }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x
            newFrame.origin.y = newValue.y - frame.size.height
            setFrame(newFrame, display: true)
        }
    }

    /// The left-bottom corner point of the window.
    @objc var leftBottom: CGPoint {
        get { frame.origin }
        set {
            setFrameOrigin(newValue)
        }
    }

    /// The bottom-right corner point of the window.
    @objc var bottomRight: CGPoint {
        get { CGPoint(x: frame.origin.x + frame.size.width, y: frame.origin.y) }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x - frame.size.width
            newFrame.origin.y = newValue.y
            setFrame(newFrame, display: true)
        }
    }

    /// The top-right corner point of the window.
    @objc var topRight: CGPoint {
        get { CGPoint(x: frame.origin.x + frame.size.width, y: frame.origin.y + frame.size.height) }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x - frame.size.width
            newFrame.origin.y = newValue.y - frame.size.height
            setFrame(newFrame, display: true)
        }
    }
}
