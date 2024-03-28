//
//  EZSelectTextPopWindow.m
//  Easydict
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZPopButtonWindow.h"
#import "EZPopButtonViewController.h"

@interface EZPopButtonWindow ()

@property (nonatomic, strong) EZPopButtonViewController *popViewController;

@end

@implementation EZPopButtonWindow

static EZPopButtonWindow *_instance;

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
    NSWindowStyleMask style = NSWindowStyleMaskBorderless;

    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        self.movableByWindowBackground = YES;
        self.level = NSNormalWindowLevel; // NSModalPanelWindowLevel;
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.backgroundColor = NSColor.clearColor;
        
        EZPopButtonViewController *popViewController = [[EZPopButtonViewController alloc] init];
        self.contentViewController = popViewController;
        self.popViewController = popViewController;
    }
    return self;
}

- (void)setPopViewController:(EZPopButtonViewController *)popViewController {
    _popViewController = popViewController;
    
    _popButton = popViewController.popButton;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

@end
