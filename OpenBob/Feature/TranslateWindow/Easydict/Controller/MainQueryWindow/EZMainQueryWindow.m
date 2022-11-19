//
//  EZMainQueryWindow.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMainQueryWindow.h"
#import "EZBaseQueryViewController.h"
#import "NSColor+MyColors.h"
#import "EZConst.h"

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
        viewController.view.size = CGSizeMake(1.5 * EZMiniQueryWindowWidth, 2 * EZMiniQueryWindowWidth);
        self.viewController = viewController;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

#pragma mark - NSNotification

- (void)windowDidResize:(NSNotification *)aNotification {
//   NSLog(@"MainWindow 窗口拉伸, (%.2f, %.2f)", self.width, self.height);
    
    if (self.viewController.resizeWindowBlock) {
        self.viewController.resizeWindowBlock();
    }
}


@end
