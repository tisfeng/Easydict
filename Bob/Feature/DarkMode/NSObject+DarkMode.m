//
//  NSObject+DarkMode.m
//  Bob
//
//  Created by chen on 2019/12/25.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSObject+DarkMode.h"
#import "DarkModeManager.h"
#import <AppKit/AppKit.h>

@implementation NSObject (DarkMode)

- (void)excuteLight:(void(^)(id x))light drak:(void(^)(id x))dark {
    @weakify(self);
    [[[RACObserve(DarkModeManager.manager, systemDarkMode) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        BOOL darkMode = [x boolValue];
        if (darkMode) {
            !dark ?: dark(self);
        } else {
            !light ?: light(self);
        }
    }];
}

@end
