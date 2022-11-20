//
//  EZWindowFrameManager.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZWindowFrameManager.h"
#import "EZBaseQueryWindow.h"

static EZWindowFrameManager *_instance;

@interface EZWindowFrameManager ()


@end

@implementation EZWindowFrameManager

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
    if (self = [super init]) {
        _mainWindowFrame = CGRectMake(0, 0, 1.5 * EZMiniQueryWindowWidth, 2 * EZMiniQueryWindowWidth);
        _fixedWindowFrame = CGRectMake(0, 0, 1.2 * EZMiniQueryWindowWidth, 2.8 * EZMiniQueryWindowWidth);
        _miniWindowFrame = CGRectMake(0, 0, EZMiniQueryWindowWidth, EZMiniQueryWindowWidth);
    }
    return self;
}

- (CGRect)windowFrameWithType:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return _mainWindowFrame;
        case EZWindowTypeFixed:
            return _fixedWindowFrame;
        case EZWindowTypeMini:
            return _miniWindowFrame;
        default:
            return _miniWindowFrame;
    }
}

- (CGRect)windowFrame:(EZBaseQueryWindow *)window {
    return [self windowFrameWithType:window.windowType];
}


@end
