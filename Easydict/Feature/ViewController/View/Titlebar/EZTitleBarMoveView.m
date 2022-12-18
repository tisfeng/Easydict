//
//  EZTitleBarMoveView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTitleBarMoveView.h"

@interface EZTitleBarMoveView ()

@property (nonatomic, assign) CGFloat mouseDragDetectionThreshold;

@end

@implementation EZTitleBarMoveView

- (instancetype)initWithFrame:(NSRect)frameRect {
    
    self = [super initWithFrame:frameRect];
    if (self) {
        _mouseDragDetectionThreshold = 1;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    if (self) {
        _mouseDragDetectionThreshold = 1;
    }
    return self;
}

- (void)mouseDown:(NSEvent *)event {
    [self mouseDragged:event];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    
    NSWindow *window = self.window;
    NSRect whereRect = [window convertRectToScreen:NSMakeRect(theEvent.locationInWindow.x, theEvent.locationInWindow.y, 1, 1)];
    NSPoint where = NSMakePoint(whereRect.origin.x, whereRect.origin.y);
    
    NSPoint origin = window.frame.origin;
    CGFloat deltaX = 0.0;
    CGFloat deltaY = 0.0;
    while ((theEvent = [NSApp nextEventMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]) && (theEvent.type != NSEventTypeLeftMouseUp)) {
        @autoreleasepool {
            NSRect nowRect = [window convertRectToScreen:NSMakeRect(theEvent.locationInWindow.x, theEvent.locationInWindow.y, 1, 1)];
            NSPoint now = NSMakePoint(nowRect.origin.x, nowRect.origin.y);
            deltaX += now.x - where.x;
            deltaY += now.y - where.y;
            if (fabs(deltaX) >= _mouseDragDetectionThreshold || fabs(deltaY) >= _mouseDragDetectionThreshold) {
                origin.x += deltaX;
                origin.y += deltaY;
                window.frameOrigin = origin;
                deltaX = 0.0;
                deltaY = 0.0;
            }
            where = now;
        }
    }
}

@end
