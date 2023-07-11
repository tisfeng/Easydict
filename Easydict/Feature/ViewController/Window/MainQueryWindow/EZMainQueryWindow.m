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

static BOOL _alive = NO;

+ (instancetype)shared {
    @synchronized (self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
            _alive = YES;
        }
    }
    return _instance;
}

+ (void)destroySharedInstance {
    [_instance close];
    _instance = nil;
    _alive = NO;
}

+ (BOOL)isAlive {
    return _alive;
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

- (void)dealloc {
    NSLog(@"EZMainQueryWindow dealloc: %@", self);
}

@end
