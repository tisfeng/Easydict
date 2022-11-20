//
//  EZMainQueryWindow.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMainQueryWindow.h"

@implementation EZMainQueryWindow

static EZMainQueryWindow *_instance;

+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[super allocWithZone:NULL] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

- (instancetype)init {
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable;
    
    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] init];
        viewController.view.frame = EZWindowFrameManager.shared.mainWindowFrame;
        self.viewController = viewController;
        self.titleBar.hidden = YES;
    }
    return self;
}

//- (EZBaseQueryViewController *)viewController {
//    if (!_viewController) {
//        EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] init];
//        viewController.view.frame = EZWindowFrameManager.shared.miniWindowFrame;
//        _viewController = viewController;
//    }
//    return _viewController;
//}

- (EZWindowType)windowType {
    return EZWindowTypeMain;
}


- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

@end
