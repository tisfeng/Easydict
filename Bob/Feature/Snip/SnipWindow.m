//
//  SnipWindow.m
//  Bob
//
//  Created by ripper on 2019/11/27.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "SnipWindow.h"
#import "Snip.h"
#import <Carbon/Carbon.h>

@implementation SnipWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {
    if (self = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag]) {
        [self setAcceptsMouseMovedEvents:YES];
        [self setFloatingPanel:YES];
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
        [self setMovableByWindowBackground:NO];
        [self setExcludedFromWindowsMenu:YES];
        [self setAlphaValue:1.0];
        [self setOpaque:NO];
        [self setHasShadow:NO];
        [self setHidesOnDeactivate:NO];
        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setMovable:NO];
        [self setLevel:kCGMaximumWindowLevel];
        [self setReleasedWhenClosed:YES];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    if ([event keyCode] == kVK_Escape) {
        [Snip.shared stop];
        return;
    }
    [super keyDown:event];
}

@end
