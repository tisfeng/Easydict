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
        self.styleMask = NSWindowStyleMaskTitled; // mini window cannot resize.
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
    NSLog(@"mini window dealloc: %@", self);
}

@end
