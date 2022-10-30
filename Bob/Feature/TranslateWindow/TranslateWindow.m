//
//  TranslateWindow.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

// https://stackoverflow.com/questions/8115811/xcode-4-cocoa-title-bar-removing-from-interface-builders-disables-textview-from
// https://stackoverflow.com/questions/17779603/subviews-become-disabled-when-title-bar-is-hidden?rq=1

#import "TranslateWindow.h"

@implementation TranslateWindow

- (instancetype)init {
    if (self = [super initWithContentRect:CGRectZero
                                styleMask: NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                  backing:NSBackingStoreBuffered
                                    defer:YES]) {
        self.movableByWindowBackground = YES;
        self.level = NSModalPanelWindowLevel;
        self.backgroundColor = [NSColor clearColor];
        self.hasShadow = YES;
        self.opaque = NO;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

@end
