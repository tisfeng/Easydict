//
//  EZMainQueryWindow.m
//  Easydict
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
    if (self = [super initWithWindowType:EZWindowTypeMain]) {
        self.titleBar.pinButton.hidden = YES;
    }
    return self;
}

#pragma mark - Rewrite

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

@end
