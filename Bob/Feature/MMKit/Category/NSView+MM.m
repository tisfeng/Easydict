//
//  NSView+MM.m
//  Bob
//
//  Created by ripper on 2019/12/1.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSView+MM.h"

@implementation NSView (MM)

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)x {
    NSRect newFrame = self.frame;
    newFrame.origin.x = x;
    self.frame = newFrame;
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)y {
    NSRect newFrame = self.frame;
    newFrame.origin.y = y;
    self.frame = newFrame;
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    NSRect newFrame = self.frame;
    newFrame.size.width = width;
    self.frame = newFrame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    NSRect newFrame = self.frame;
    newFrame.size.height = height;
    self.frame = newFrame;
}

- (CGFloat)top {
    if (self.isFlipped) {
        return self.frame.origin.y;
    }else {
        return self.frame.origin.y + self.frame.size.height;
    }
}

- (void)setTop:(CGFloat)top {
    NSRect newFrame = self.frame;
    if (self.isFlipped) {
        newFrame.origin.y = top;
    }else {
        newFrame.origin.y = top - self.frame.size.height;
    }
    self.frame = newFrame;
}

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)left {
    NSRect newFrame = self.frame;
    newFrame.origin.x = left;
    self.frame = newFrame;
}

- (CGFloat)bottom {
    if (self.isFlipped) {
        return self.frame.origin.y + self.frame.size.height;
    }else {
        return self.frame.origin.y;
    }
}

- (void)setBottom:(CGFloat)bottom {
    NSRect newFrame = self.frame;
    if (self.isFlipped) {
        newFrame.origin.y = bottom - self.frame.size.height;
    }else {
        newFrame.origin.y = bottom;
    }
    self.frame = newFrame;
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
    NSRect newFrame = self.frame;
    newFrame.origin.x = right - self.frame.size.width;
    self.frame = newFrame;
}

- (CGFloat)centerX {
    return NSMidX(self.frame);
}

- (void)setCenterX:(CGFloat)centerX {
    NSRect newFrame = self.frame;
    newFrame.origin.x = centerX - self.frame.size.width * 0.5;
    self.frame = newFrame;
}

- (CGFloat)centerY {
    return NSMidY(self.frame);
}

- (void)setCenterY:(CGFloat)centerY {
    NSRect newFrame = self.frame;
    newFrame.origin.y = centerY - self.frame.size.height * 0.5;
    self.frame = newFrame;
}

- (NSPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(NSPoint)origin {
    NSRect newFrame = self.frame;
    newFrame.origin = origin;
    self.frame = newFrame;
}

- (NSSize)size {
    return self.frame.size;
}

- (void)setSize:(NSSize)size {
    NSRect newFrame = self.frame;
    newFrame.size = size;
    self.frame = newFrame;
}

- (NSPoint)center {
    return NSMakePoint(NSMidX(self.frame), NSMidY(self.frame));
}

- (void)setCenter:(NSPoint)center {
    NSRect newFrame = self.frame;
    newFrame.origin.x = center.x - self.frame.size.width * 0.5;
    newFrame.origin.y = center.y - self.frame.size.height * 0.5;
    self.frame = newFrame;
}

- (NSPoint)topLeft {
    if (self.isFlipped) {
        return self.frame.origin;
    }else {
        return NSMakePoint(self.frame.origin.x, self.frame.origin.y + self.frame.size.height);
    }
}

- (void)setTopLeft:(NSPoint)topLeft {
    NSRect newFrame = self.frame;
    if (self.isFlipped) {
        newFrame.origin = topLeft;
    }else {
        newFrame.origin.x = topLeft.x;
        newFrame.origin.y = topLeft.y - self.frame.size.height;
    }
    self.frame = newFrame;
}

- (NSPoint)leftBottom {
    if (self.isFlipped) {
        return NSMakePoint(self.frame.origin.x, self.frame.origin.y + self.frame.size.height);
    }else {
        return self.frame.origin;
    }
}

- (void)setLeftBottom:(NSPoint)leftBottom {
    NSRect newFrame = self.frame;
    if (self.isFlipped) {
        newFrame.origin.x = leftBottom.x;
        newFrame.origin.y = leftBottom.y - self.frame.size.height;
    }else {
        newFrame.origin = leftBottom;
    }
    self.frame = newFrame;
}

- (NSPoint)bottomRight {
    if (self.isFlipped) {
        return NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y + self.frame.size.height);
    }else {
        return NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y);
    }
}

- (void)setBottomRight:(NSPoint)bottomRight {
    NSRect newFrame = self.frame;
    if (self.isFlipped) {
        newFrame.origin.x = bottomRight.x - self.frame.size.width;
        newFrame.origin.y = bottomRight.y - self.frame.size.height;
    }else {
        newFrame.origin.x = bottomRight.x - self.frame.size.width;
        newFrame.origin.y = bottomRight.y;
    }
    self.frame = newFrame;
}

- (NSPoint)topRight {
    if (self.isFlipped) {
        return NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y);
    }else {
        return NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y + self.frame.size.height);
    }
}

- (void)setTopRight:(NSPoint)topRight {
    NSRect newFrame = self.frame;
    if (self.isFlipped) {
        newFrame.origin.x = topRight.x - self.frame.size.width;
        newFrame.origin.y = topRight.y;
    }else {
        newFrame.origin.x = topRight.x - self.frame.size.width;
        newFrame.origin.y = topRight.y - self.frame.size.height;
    }
    self.frame = newFrame;
}

@end
