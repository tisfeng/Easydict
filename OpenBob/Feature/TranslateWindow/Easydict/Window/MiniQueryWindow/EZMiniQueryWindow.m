//
//  EZMiniQueryWindow.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMiniQueryWindow.h"
#import "EZBaseQueryViewController.h"
#import "NSColor+MyColors.h"
#import "EZConst.h"

@implementation EZMiniQueryWindow


- (instancetype)init {
    NSWindowStyleMask style = NSWindowStyleMaskTitled;
    
    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] init];
        self.viewController = viewController;
    }
    return self;
}

//- (instancetype)init {
//    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;
//
//    CGRect rect = CGRectMake(0, 0, EZMiniQueryWindowWidth, EZMiniQueryWindowWidth);
//    if (self = [super initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
//        self.movableByWindowBackground = YES;
//        self.level = NSModalPanelWindowLevel; // NSNormalWindowLevel
//        self.titlebarAppearsTransparent = YES;
//        self.titleVisibility = NSWindowTitleHidden;
//
//        [self excuteLight:^(NSWindow *window) {
//            window.backgroundColor = NSColor.mainViewBgLightColor;
//        } drak:^(NSWindow *window) {
//            window.backgroundColor = NSColor.mainViewBgDarkColor;
//        }];
//
//        EZBaseQueryViewController *miniVC = [[EZBaseQueryViewController alloc] init];
//        self.contentViewController = miniVC;
//    }
//    return self;
//}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (void)dealloc {
    NSLog(@"mini window dealloc: %@", self);
}

@end
