//
//  EZBaseQueryWindow.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaseQueryWindow.h"
#import "EZBaseQueryViewController.h"
#import "NSColor+MyColors.h"

@interface EZBaseQueryWindow () <NSWindowDelegate>

@end

@implementation EZBaseQueryWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {
    if (self = [super initWithContentRect:contentRect styleMask:style backing:NSBackingStoreBuffered defer:flag]) {
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel; // NSModalPanelWindowLevel;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.delegate = self;
        
        [self excuteLight:^(NSWindow *window) {
            window.backgroundColor = NSColor.mainViewBgLightColor;
        } drak:^(NSWindow *window) {
            window.backgroundColor = NSColor.mainViewBgDarkColor;
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidResize:)
                                                     name:NSWindowDidResizeNotification
                                                   object:self];
    }
    return self;
}

- (instancetype)init {
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;
    return [self initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES];
}

- (void)setViewController:(EZBaseQueryViewController *)viewController {
    _viewController = viewController;
    
    self.contentViewController = viewController;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}


#pragma makr - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
//    NSLog(@"windowDidBecomeKey: %@", self);
}

#pragma mark - NSNotification

- (void)windowDidResize:(NSNotification *)aNotification {
//   NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);
    
    if (self.viewController.resizeWindowBlock) {
        self.viewController.resizeWindowBlock();
    }
}

@end
