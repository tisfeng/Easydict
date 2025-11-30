//
//  NSView+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSView {
    /// The x coordinate of the view's frame origin.
    @objc var x: CGFloat {
        get { frame.origin.x }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue
            frame = newFrame
        }
    }

    /// The y coordinate of the view's frame origin.
    @objc var y: CGFloat {
        get { frame.origin.y }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue
            frame = newFrame
        }
    }

    /// The width of the view's frame.
    @objc var width: CGFloat {
        get { frame.size.width }
        set {
            var newFrame = frame
            newFrame.size.width = newValue
            frame = newFrame
        }
    }

    /// The height of the view's frame.
    @objc var height: CGFloat {
        get { frame.size.height }
        set {
            var newFrame = frame
            newFrame.size.height = newValue
            frame = newFrame
        }
    }

    /// The top edge position of the view.
    @objc var top: CGFloat {
        get { isFlipped ? frame.origin.y : frame.origin.y + frame.size.height }
        set {
            var newFrame = frame
            if isFlipped {
                newFrame.origin.y = newValue
            } else {
                newFrame.origin.y = newValue - frame.size.height
            }
            frame = newFrame
        }
    }

    /// The left edge position of the view.
    @objc var left: CGFloat {
        get { frame.origin.x }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue
            frame = newFrame
        }
    }

    /// The bottom edge position of the view.
    @objc var bottom: CGFloat {
        get { isFlipped ? frame.origin.y + frame.size.height : frame.origin.y }
        set {
            var newFrame = frame
            if isFlipped {
                newFrame.origin.y = newValue - frame.size.height
            } else {
                newFrame.origin.y = newValue
            }
            frame = newFrame
        }
    }

    /// The right edge position of the view.
    @objc var right: CGFloat {
        get { frame.origin.x + frame.size.width }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue - frame.size.width
            frame = newFrame
        }
    }

    /// The x coordinate of the view's center point.
    @objc var centerX: CGFloat {
        get { frame.midX }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue - frame.size.width * 0.5
            frame = newFrame
        }
    }

    /// The y coordinate of the view's center point.
    @objc var centerY: CGFloat {
        get { frame.midY }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue - frame.size.height * 0.5
            frame = newFrame
        }
    }

    /// The origin point of the view's frame.
    @objc var origin: CGPoint {
        get { frame.origin }
        set {
            var newFrame = frame
            newFrame.origin = newValue
            frame = newFrame
        }
    }

    /// The size of the view's frame.
    @objc var size: CGSize {
        get { frame.size }
        set {
            var newFrame = frame
            newFrame.size = newValue
            frame = newFrame
        }
    }

    /// The center point of the view.
    @objc var center: CGPoint {
        get { CGPoint(x: frame.midX, y: frame.midY) }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x - frame.size.width * 0.5
            newFrame.origin.y = newValue.y - frame.size.height * 0.5
            frame = newFrame
        }
    }

    /// The top-left corner point of the view.
    @objc var topLeft: CGPoint {
        get {
            isFlipped ? frame.origin : CGPoint(x: frame.origin.x, y: frame.origin.y + frame.size.height)
        }
        set {
            var newFrame = frame
            if isFlipped {
                newFrame.origin = newValue
            } else {
                newFrame.origin.x = newValue.x
                newFrame.origin.y = newValue.y - frame.size.height
            }
            frame = newFrame
        }
    }

    /// The left-bottom corner point of the view.
    @objc var leftBottom: CGPoint {
        get {
            isFlipped ? CGPoint(x: frame.origin.x, y: frame.origin.y + frame.size.height) : frame.origin
        }
        set {
            var newFrame = frame
            if isFlipped {
                newFrame.origin.x = newValue.x
                newFrame.origin.y = newValue.y - frame.size.height
            } else {
                newFrame.origin = newValue
            }
            frame = newFrame
        }
    }

    /// The bottom-right corner point of the view.
    @objc var bottomRight: CGPoint {
        get {
            CGPoint(x: frame.origin.x + frame.size.width, y: frame.origin.y)
        }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x - frame.size.width
            newFrame.origin.y = newValue.y
            frame = newFrame
        }
    }

    /// The top-right corner point of the view.
    @objc var topRight: CGPoint {
        get {
            CGPoint(x: frame.origin.x + frame.size.width, y: frame.origin.y + frame.size.height)
        }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue.x - frame.size.width
            newFrame.origin.y = newValue.y - frame.size.height
            frame = newFrame
        }
    }
}
