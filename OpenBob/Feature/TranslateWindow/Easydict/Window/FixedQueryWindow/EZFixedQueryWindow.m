//
//  MainWindow.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZFixedQueryWindow.h"

@implementation EZFixedQueryWindow

static EZFixedQueryWindow *_instance;

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
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable;
    
    if (self = [super initWithContentRect:CGRectZero styleMask:style backing:NSBackingStoreBuffered defer:YES]) {
        EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] init];
        viewController.view.size = CGSizeMake(1.2 * EZMiniQueryWindowWidth, 2.8 * EZMiniQueryWindowWidth);
        self.viewController = viewController;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

#pragma mark - NSNotification

- (void)windowDidResize:(NSNotification *)aNotification {
//   NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);
    
    EZBaseQueryViewController *mainVC = (EZBaseQueryViewController *)self.contentViewController;
    if (mainVC.resizeWindowBlock) {
        mainVC.resizeWindowBlock();
    }
}

@end
