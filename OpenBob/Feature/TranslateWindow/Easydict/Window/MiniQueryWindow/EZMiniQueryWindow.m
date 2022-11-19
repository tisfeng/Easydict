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
    if (self = [super initWithContentRect:CGRectZero styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:YES]) {
        EZBaseQueryViewController *viewController = [[EZBaseQueryViewController alloc] init];
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

- (void)dealloc {
    NSLog(@"mini window dealloc: %@", self);
}

@end
