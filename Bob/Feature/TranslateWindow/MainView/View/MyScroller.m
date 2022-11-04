//
//  MyScroller.m
//  Bob
//
//  Created by tisfeng on 2022/11/4.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "MyScroller.h"

@implementation MyScroller

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.scrollerStyle = NSScrollerStyleOverlay;
        self.controlSize = NSControlSizeSmall;
        [self commonInitializer];
    }
    return self;
}


+ (CGFloat)scrollerWidthForControlSize:(NSControlSize)controlSize scrollerStyle:(NSScrollerStyle)scrollerStyle {
    return 12;
}

//- (void)drawKnob {
//    [super drawKnob];
//
//    NSRect knobRect = [self rectForPart:NSScrollerKnob];
//
//    CGFloat width = [MyScroller scrollerWidthForControlSize:self.controlSize scrollerStyle:self.scrollerStyle];
//        NSRect newRect = NSMakeRect((knobRect.size.width - width) / 2, knobRect.origin.y, width, knobRect.size.height);
//        NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:3 yRadius:3];
//        [[NSColor grayColor] set];
//
////    NSRect knobRect = NSInsetRect([self rectForPart:NSScrollerKnob], 3, 0);
////    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:3 yRadius:3];
//    [[NSColor grayColor] set];
//    [bezierPath fill];
//}



- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInitializer];
}

- (void)commonInitializer {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                    options:(
                                                                             NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingMouseMoved)
                                                                      owner:self
                                                                   userInfo:nil];
        [self addTrackingArea:trackingArea];
    });
}

- (void)drawRect:(NSRect)dirtyRect {
    // Do some custom drawing...

    // Call NSScroller's drawKnob method (or your own if you overrode it)
    [self drawKnob];
}

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag {
    // Don't draw the background. Should only be invoked when using overlay scrollers
}


- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    [self fadeOut];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.1f;
        [self.animator setAlphaValue:1.0f];
    } completionHandler:^{
    }];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOut) object:nil];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [super mouseMoved:theEvent];
    self.alphaValue = 1.0f;
}

- (void)setFloatValue:(float)aFloat {
    [super setFloatValue:aFloat];
    [self.animator setAlphaValue:1.0f];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOut) object:nil];
    [self performSelector:@selector(fadeOut) withObject:nil afterDelay:1.5f];
}

- (void)fadeOut {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3f;
        [self.animator setAlphaValue:0.0f];
    } completionHandler:^{
    }];
}

+ (BOOL)isCompatibleWithOverlayScrollers {
    return self == [MyScroller class];
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//
//    // Drawing code here.
//}

@end
