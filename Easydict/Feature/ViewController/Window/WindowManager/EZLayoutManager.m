//
//  EZWindowFrameManager.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLayoutManager.h"
#import "EZBaseQueryWindow.h"
#import "EZConfiguration.h"

@interface EZLayoutManager ()

@property (nonatomic, assign) CGSize minimumWindowSize;
@property (nonatomic, assign) CGSize maximumWindowSize;

@end

@implementation EZLayoutManager

static EZLayoutManager *_instance;

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
    self.screen = NSScreen.mainScreen;
    self.minimumWindowSize = CGSizeMake(300, 70);
    
    EZConfiguration *configuration = [EZConfiguration shared];
    
    self.miniWindowFrame = [configuration windowFrameWithType:EZWindowTypeMini];
    if (CGRectEqualToRect(self.miniWindowFrame, CGRectZero)) {
        self.miniWindowFrame = [self defaultWindowFrameWithType:EZWindowTypeMini];
        [configuration setWindowFrame:self.miniWindowFrame windowType:EZWindowTypeMini];
    }
    
    self.fixedWindowFrame = [configuration windowFrameWithType:EZWindowTypeFixed];
    if (CGRectEqualToRect(self.fixedWindowFrame, CGRectZero)) {
        self.fixedWindowFrame = [self defaultWindowFrameWithType:EZWindowTypeFixed];
        [configuration setWindowFrame:self.fixedWindowFrame windowType:EZWindowTypeFixed];
    }
    
    self.mainWindowFrame = [configuration windowFrameWithType:EZWindowTypeMain];
    if (CGRectEqualToRect(self.mainWindowFrame, CGRectZero)) {
        self.mainWindowFrame = [self defaultWindowFrameWithType:EZWindowTypeMain];
        [configuration setWindowFrame:self.mainWindowFrame windowType:EZWindowTypeMain];
    }
}

- (void)setScreen:(NSScreen *)screen {
    _screen = screen;
    
    [self setupMaximumWindowSize:screen];
}

- (void)setupMaximumWindowSize:(NSScreen *)screen {
    CGSize visibleFrameSize = screen.visibleFrame.size;
    self.maximumWindowSize = CGSizeMake(visibleFrameSize.width, visibleFrameSize.height);
}

- (CGSize)minimumWindowSize:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return self.minimumWindowSize;
        case EZWindowTypeFixed:
            return self.minimumWindowSize;
        case EZWindowTypeMini:
            return self.minimumWindowSize;
        default:
            return self.minimumWindowSize;
    }
}

- (CGSize)maximumWindowSize:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return self.maximumWindowSize;
        case EZWindowTypeFixed:
            return self.maximumWindowSize;
        case EZWindowTypeMini: {
            return self.maximumWindowSize;
        }
        default:
            return self.maximumWindowSize;
    }
}


- (CGFloat)inputViewMinHeight:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return 75; // three line
        case EZWindowTypeFixed:
            return 65; // > two line
        case EZWindowTypeMini:
            return 44; // > one line.
        default:
            return 54; // two line
    }
}

- (CGFloat)inputViewMaxHeight:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return NSScreen.mainScreen.frame.size.height * 0.3;
        case EZWindowTypeFixed:
            return NSScreen.mainScreen.frame.size.height * 0.3;
        case EZWindowTypeMini:
            return 75; // 3 line
        default:
            return 75;
    }
}

- (CGRect)windowFrameWithType:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain: {
            return self.mainWindowFrame;
        }
        case EZWindowTypeFixed: {
            return self.fixedWindowFrame;
        }
        case EZWindowTypeMini: {
            return self.miniWindowFrame;
        }
        default: {
            return CGRectZero;
        }
    }
}

- (CGRect)defaultWindowFrameWithType:(EZWindowType)type {
    CGSize visibleFrameSize = NSScreen.mainScreen.visibleFrame.size;
    CGPoint centerPoint = NSMakePoint(visibleFrameSize.width / 2, visibleFrameSize.height / 2);
    CGFloat rateableWidth = 1727.0 / NSScreen.mainScreen.frame.size.width;
    CGFloat mainWindowWidth = 500 * rateableWidth;
    CGFloat miniWindowWidth = 420 * rateableWidth; // My MacBook screen ratio
    CGFloat fixedWindowWidth = 420 * rateableWidth;
    CGRect frame = CGRectZero;
    
    switch (type) {
        case EZWindowTypeMain: {
            frame = CGRectMake(centerPoint.x,
                               centerPoint.y,
                               mainWindowWidth,
                               self.minimumWindowSize.height);
            break;
        }
        case EZWindowTypeFixed: {
            frame = CGRectMake(centerPoint.x,
                               centerPoint.y,
                               fixedWindowWidth,
                               self.minimumWindowSize.height);
            break;
        }
        case EZWindowTypeMini: {
            frame = CGRectMake(centerPoint.x,
                               centerPoint.y,
                               miniWindowWidth,
                               self.minimumWindowSize.height);
            break;
        }
        default: {
            return CGRectZero;
        }
    }
    return frame;
}

- (CGRect)windowFrame:(EZBaseQueryWindow *)window {
    return [self windowFrameWithType:window.windowType];
}

- (void)updateWindowFrame:(EZBaseQueryWindow *)window {
    EZWindowType windowType = window.windowType;
    switch (windowType) {
        case EZWindowTypeMain:
            _mainWindowFrame = window.frame;
            break;
        case EZWindowTypeFixed:
            _fixedWindowFrame = window.frame;
            break;
        case EZWindowTypeMini:
            _miniWindowFrame = window.frame;
            break;
        default:
            break;
    }
    
    [EZConfiguration.shared setWindowFrame:window.frame windowType:windowType];
}

@end
