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
                                styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                  backing:NSBackingStoreBuffered
                                    defer:YES]) {
        self.movableByWindowBackground = YES;
        self.level = NSModalPanelWindowLevel;
        self.backgroundColor = [NSColor clearColor];
        self.hasShadow = YES;
        self.opaque = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidResize:)
                                                     name:NSWindowDidResizeNotification
                                                   object:self];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)windowDidResize:(NSNotification *)aNotification {
    NSLog(@"窗口拉伸, (%.2f, %.2f)", self.width, self.height);
    
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSLog(@"oldSize: %@", @(oldSize));
    // 根据需要调整NSView上面的别的控件和视图的frame
}

//- (NSSize)resizeIncrements {
//    return CGSizeMake(300, 300);
//}

@end
