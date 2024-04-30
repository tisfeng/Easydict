//
//  EZMiniQueryWindow.m
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMiniQueryWindow.h"

@implementation EZMiniQueryWindow

- (instancetype)init {
    if (self = [super initWithWindowType:EZWindowTypeMini]) {
        [self standardWindowButton:NSWindowCloseButton].hidden = YES;
        [self standardWindowButton:NSWindowMiniaturizeButton].hidden = YES;
        [self standardWindowButton:NSWindowZoomButton].hidden = YES;
    }
    return self;
}

#pragma mark - Rewrite

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (void)dealloc {
    MMLogInfo(@"mini window dealloc: %@", self);
}

@end
