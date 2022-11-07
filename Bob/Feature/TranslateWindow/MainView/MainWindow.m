//
//  MainWindow.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "MainWindow.h"
#import "MainViewController.h"
#import "NSColor+MyColors.h"

@implementation MainWindow

static MainWindow *_instance;

+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (instancetype)init {
    NSWindowStyleMask style = NSWindowStyleMaskTitled |  NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;
    
    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel; // NSModalPanelWindowLevel;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;

        [self excuteLight:^(NSWindow *window) {
            window.backgroundColor = NSColor.mainViewBgLightColor;
        } drak:^(NSWindow *window) {
            window.backgroundColor = NSColor.mainViewBgDarkColor;
        }];
        
        MainViewController *vc = [[MainViewController alloc] init];
        self.contentViewController = vc;
        
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
//    NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);
}

@end
