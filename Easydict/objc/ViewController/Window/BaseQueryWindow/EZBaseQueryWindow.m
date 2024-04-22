//
//  EZBaseQueryWindow.m
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaseQueryWindow.h"
#import "EZTitlebar.h"
#import "EZWindowManager.h"
#import "NSImage+EZResize.h"

@interface EZBaseQueryWindow () <NSWindowDelegate, NSToolbarDelegate>

@end

@implementation EZBaseQueryWindow

- (instancetype)initWithWindowType:(EZWindowType)type {
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;
    
    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        self.windowType = type;
        
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.delegate = self;
        
        // !!!: must set backgroundColor
        [self excuteLight:^(NSWindow *window) {
            window.backgroundColor = [NSColor ez_mainViewBgLightColor];
        } dark:^(NSWindow *window) {
            window.backgroundColor = [NSColor ez_mainViewBgDarkColor];
        }];
        
        [self setupUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidResize:)
                                                     name:NSWindowDidResizeNotification
                                                   object:self];
    }
    return self;
}

- (void)setupUI {
    NSView *themeView = self.contentView.superview;
    NSView *titleView = themeView.subviews[1];
    
    self.titleBar = [[EZTitlebar alloc] initWithFrame:CGRectMake(0, 0, self.width, 30)];
    [titleView addSubview:self.titleBar];
    [self.titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(titleView);
    }];
    
    mm_weakify(self);
    self.titleBar.menuActionBlock = ^(EZTitlebarQuickAction action) {
        mm_strongify(self);
        [self.queryViewController receiveTitlebarAction:action];
    };
}


#pragma mark - Setter

- (void)setWindowType:(EZWindowType)windowType {
    _windowType = windowType;
    
    EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] initWithWindowType:windowType];
    self.queryViewController = viewController;
}

- (void)setQueryViewController:(EZBaseQueryViewController *)viewController {
    _queryViewController = viewController;
    
    viewController.baseQueryWindow = self;
    self.contentViewController = viewController;
}

- (void)setPin:(BOOL)pin {
    _pin = pin;
     
    // !!!: Do not use kCGMaximumWindowLevel, otherwise it will obscure the tooltip.
    NSWindowLevel level = self.pin ? kCGUtilityWindowLevel : kCGNormalWindowLevel;
    self.level = level;
}

#pragma mark - Rewrite

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame {
    return EZUpdateTableViewRowHeightAnimationDuration;
}


- (void)dealloc {
    MMLogInfo(@"dealloc: %@", self);
}

#pragma mark - NSWindowDelegate, NSNotification

- (void)windowDidBecomeKey:(NSNotification *)notification {
//    MMLogInfo(@"windowDidBecomeKey: %@", self);
    
    // We need to update the window type when the window becomes the key window.
    [EZWindowManager.shared updateFloatingWindowType:self.windowType isShowing:YES];
    
    if (self.didBecomeKeyWindowBlock) {
        self.didBecomeKeyWindowBlock();
    }
}

- (void)windowDidResignKey:(NSNotification *)notification {
//    MMLogInfo(@"windowDidResignKey: %@", self);
    
    // Close floating window when losing focus if it's not pinned or main window.
    [EZWindowManager.shared closeFloatingWindowIfNotPinned:self.windowType exceptWindowType:EZWindowTypeMain];
}

- (void)windowDidResize:(NSNotification *)aNotification {
    MMLogInfo(@"windowDidResize: %@, windowType: %ld", @(self.frame), self.windowType);

    [[EZLayoutManager shared] updateWindowFrame:self];
    
    if (self.resizeWindowBlock) {
        self.resizeWindowBlock();
    }
    
    if (self.queryViewController.resizeWindowBlock) {
        self.queryViewController.resizeWindowBlock();
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    [[EZLayoutManager shared] updateWindowFrame:self];
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    return YES;
}

// Window is hidden or showing.
- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
//    MMLogInfo(@"window Did Change Occlusion State");
    
    // Window is obscured
    if (self.occlusionState != NSWindowOcclusionStateVisible) {
        
    }
}

@end
