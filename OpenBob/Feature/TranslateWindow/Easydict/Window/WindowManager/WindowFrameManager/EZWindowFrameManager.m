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
        [self commonInitialize];
    }
    return self;
}

- (void)commonInitialize {
    self.miniWindowWidth = 300;
    self.miniWindowHeight = 200;
    self.maxWindowHeight = NSScreen.mainScreen.visibleFrame.size.height; // 1079
    
    self.inputViewMiniHeight = 60;
    self.inputViewMaxHeight = NSScreen.mainScreen.frame.size.height / 3; // 372
    
    self.miniWindowFrame = CGRectMake(0, 0, self.miniWindowWidth, self.miniWindowHeight);
    self.fixedWindowFrame = self.miniWindowFrame;
    self.mainWindowFrame = self.miniWindowFrame;
}


- (CGFloat)getInputViewMiniHeight:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return 60;
        case EZWindowTypeFixed:
            return 60;
        case EZWindowTypeMini:
            return 30; // one line
        default:
            return 30;
    }
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
