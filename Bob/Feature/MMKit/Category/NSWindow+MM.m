//
//  NSWindow+MM.m
//  Bob
//
//  Created by ripper on 2019/12/1.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSWindow+MM.h"

@implementation NSWindow (MM)

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)x {
    NSRect newFrame = self.frame;
    newFrame.origin.x = x;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)y {
    NSRect newFrame = self.frame;
    newFrame.origin.y = y;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    NSRect newFrame = self.frame;
    newFrame.size.width = width;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    NSRect newFrame = self.frame;
    newFrame.size.height = height;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)top {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setTop:(CGFloat)top {
    NSRect newFrame = self.frame;
    newFrame.origin.y = top - self.frame.size.height;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)left {
    NSRect newFrame = self.frame;
    newFrame.origin.x = left;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)bottom {
    return self.frame.origin.y;
}

- (void)setBottom:(CGFloat)bottom {
    NSRect newFrame = self.frame;
    newFrame.origin.y = bottom;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
    NSRect newFrame = self.frame;
    newFrame.origin.x = right - self.frame.size.width;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)centerX {
    return NSMidX(self.frame);
}

- (void)setCenterX:(CGFloat)centerX {
    NSRect newFrame = self.frame;
    newFrame.origin.x = centerX - self.frame.size.width * 0.5;
    [self setFrame:newFrame display:YES];
}

- (CGFloat)centerY {
    return NSMidY(self.frame);
}

- (void)setCenterY:(CGFloat)centerY {
    NSRect newFrame = self.frame;
    newFrame.origin.y = centerY - self.frame.size.height * 0.5;
    [self setFrame:newFrame display:YES];
}

- (NSPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(NSPoint)origin {
    NSRect newFrame = self.frame;
    newFrame.origin = origin;
    [self setFrame:newFrame display:YES];
}

- (NSSize)size {
    return self.frame.size;
}

- (void)setSize:(NSSize)size {
    NSRect newFrame = self.frame;
    newFrame.size = size;
    [self setFrame:newFrame display:YES];
}

- (NSPoint)centerPoint {
    return NSMakePoint(NSMidX(self.frame), NSMidY(self.frame));
}

- (void)setCenterPoint:(NSPoint)center {
    NSRect newFrame = self.frame;
    newFrame.origin.x = center.x - self.frame.size.width * 0.5;
    newFrame.origin.y = center.y - self.frame.size.height * 0.5;
    [self setFrame:newFrame display:YES];
}

- (NSPoint)topLeft {
    return NSMakePoint(self.frame.origin.x, self.frame.origin.y + self.frame.size.height);
}

- (void)setTopLeft:(NSPoint)topLeft {
    NSRect newFrame = self.frame;
    newFrame.origin.x = topLeft.x;
    newFrame.origin.y = topLeft.y - self.frame.size.height;
    [self setFrame:newFrame display:YES];
}

- (NSPoint)leftBottom {
    return self.frame.origin;
}

- (void)setLeftBottom:(NSPoint)leftBottom {
    NSRect newFrame = self.frame;
    newFrame.origin = leftBottom;
    [self setFrame:newFrame display:YES];
}

- (NSPoint)bottomRight {
    return NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y);
}

- (void)setBottomRight:(NSPoint)bottomRight {
    NSRect newFrame = self.frame;
    newFrame.origin.x = bottomRight.x - self.frame.size.width;
    newFrame.origin.y = bottomRight.y;
    [self setFrame:newFrame display:YES];
}

- (NSPoint)topRight {
    return NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y + self.frame.size.height);
}

- (void)setTopRight:(NSPoint)topRight {
    NSRect newFrame = self.frame;
    newFrame.origin.x = topRight.x - self.frame.size.width;
    newFrame.origin.y = topRight.y - self.frame.size.height;
    [self setFrame:newFrame display:YES];
}

@end
