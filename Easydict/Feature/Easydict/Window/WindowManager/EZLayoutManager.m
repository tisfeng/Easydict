//
//  EZWindowFrameManager.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLayoutManager.h"
#import "EZBaseQueryWindow.h"


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
    self.minimumWindowSize = CGSizeMake(300, 200);
    
    CGSize visibleFrameSize = NSScreen.mainScreen.visibleFrame.size;
    self.maximumWindowSize = CGSizeMake(visibleFrameSize.width / 2, visibleFrameSize.height);

    CGPoint centerPoint = NSMakePoint(visibleFrameSize.width / 2, visibleFrameSize.height / 2);
    self.miniWindowFrame = CGRectMake(centerPoint.x,
                                      centerPoint.y,
                                      self.minimumWindowSize.width,
                                      self.minimumWindowSize.height);
    self.fixedWindowFrame = self.miniWindowFrame;
    self.mainWindowFrame = self.miniWindowFrame;
}

- (CGSize)minimumWindowSize:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMini:
            return self.minimumWindowSize;
        case EZWindowTypeFixed:
            return self.minimumWindowSize;
        case EZWindowTypeMain:
            return self.minimumWindowSize;
        default:
            return self.minimumWindowSize;
    }
}

- (CGSize)maximumWindowSize:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMini:
            return self.maximumWindowSize;
        case EZWindowTypeFixed:
            return self.maximumWindowSize;
        case EZWindowTypeMain:
            return self.maximumWindowSize;
        default:
            return self.maximumWindowSize;
    }
}


- (CGFloat)inputViewMiniHeight:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return 60;
        case EZWindowTypeFixed:
            return 60;
        case EZWindowTypeMini:
            return EZInputViewMiniHeight; // two line
        default:
            return EZInputViewMiniHeight;
    }
}

- (CGFloat)inputViewMaxHeight:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return NSScreen.mainScreen.frame.size.height / 3;
        case EZWindowTypeFixed:
            return NSScreen.mainScreen.frame.size.height / 3;
        case EZWindowTypeMini:
            return EZInputViewMiniHeight; // two line
        default:
            return EZInputViewMiniHeight;
    }
}

- (CGSize)textContainerInset:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return CGSizeMake(8, 8);
        case EZWindowTypeFixed:
            return CGSizeMake(8, 8);
        case EZWindowTypeMini:
            return CGSizeMake(4, 4);
        default:
            return CGSizeMake(4, 4);
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
