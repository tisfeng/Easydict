//
//  EZWindowFrameManager.m
//  Easydict
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
    self.minimumWindowSize = CGSizeMake(300, 100);
    
    CGSize visibleFrameSize = NSScreen.mainScreen.visibleFrame.size;
    self.maximumWindowSize = CGSizeMake(visibleFrameSize.width / 2, visibleFrameSize.height);
    
    CGPoint centerPoint = NSMakePoint(visibleFrameSize.width / 2, visibleFrameSize.height / 2);
    CGFloat rateableWidth = 1727.0 / NSScreen.mainScreen.frame.size.width;
    CGFloat miniWindowWidth = 400 * rateableWidth; // My MacBook screen ratio
    self.miniWindowFrame = CGRectMake(centerPoint.x,
                                      centerPoint.y,
                                      miniWindowWidth,
                                      self.minimumWindowSize.height);
    
    CGFloat fixedWindowWidth = 360 * rateableWidth;
    self.fixedWindowFrame = CGRectMake(centerPoint.x,
                                       centerPoint.y,
                                       fixedWindowWidth,
                                       self.minimumWindowSize.height);
    
    CGFloat mainWindowWidth = 480 * rateableWidth;
    self.mainWindowFrame = CGRectMake(centerPoint.x,
                                      centerPoint.y,
                                      mainWindowWidth,
                                      self.minimumWindowSize.height);
}

- (CGSize)minimumWindowSize:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return self.minimumWindowSize;
        case EZWindowTypeFixed:
            return self.minimumWindowSize;
        case EZWindowTypeMini:
            return CGSizeMake(self.miniWindowFrame.size.width, self.minimumWindowSize.height);
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
            return CGSizeMake(self.miniWindowFrame.size.width, self.maximumWindowSize.height);
        }
        default:
            return self.maximumWindowSize;
    }
}


- (CGFloat)inputViewMiniHeight:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return 70;
        case EZWindowTypeFixed:
            return 65;
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
            return CGSizeMake(8, 4);
        default:
            return CGSizeMake(8, 4);
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

- (void)updateWindowFrame:(EZBaseQueryWindow *)window {
    switch (window.windowType) {
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
}

- (NSString *)windowName:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return @"main_window";
        case EZWindowTypeFixed:
            return @"fixed_window";
        case EZWindowTypeMini:
            return @"mini_window";
        default:
            return @"mini_window";
    }
}

- (MMOrderedDictionary<NSNumber *, NSString *> *)fixedWindowPostionDict {
    MMOrderedDictionary *dict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                 @(EZShowWindowPositionRight), NSLocalizedString(@"fixed_window_position_right", nil),
                                 @(EZShowWindowPositionMouse), NSLocalizedString(@"fixed_window_position_mouse", nil),
                                 @(EZShowWindowPositionFormer), NSLocalizedString(@"fixed_window_position_former", nil), nil];
    
    return dict;
}

@end
