//
//  EZWindowFrameManager.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLayoutManager.h"
#import "EZBaseQueryWindow.h"
#import "Easydict-Swift.h"

@interface EZLayoutManager ()

/// Minimum window frame size of clicked window
@property (nonatomic, assign) CGSize minimumWindowSize;
/// Maximum window frame size of clicked window
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
    self.minimumWindowSize = CGSizeMake(360, 40);

    Configuration *configuration = [Configuration shared];
    
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
    // Get maximum size from the screen's visible frame
    // self.maximumWindowSize is already set to self.screen.visibleFrame.size in setupMaximumWindowSize

    CGFloat maxWidth = self.maximumWindowSize.width;
    CGFloat maxHeight = self.maximumWindowSize.height;

    NSInteger percentage = Configuration.shared.maxWindowHeightPercentage;

    CGFloat calculatedMaxHeight = maxHeight * ((CGFloat)percentage / 100.0);

    // Ensure the calculated height is not less than the minimum window height for this type
    CGFloat minHeightForType = [self minimumWindowSize:type].height;
    CGFloat effectiveMaxHeight = MAX(minHeightForType, calculatedMaxHeight);

    // Ensure it does not exceed the original screen height (shouldn't happen if percentage <= 100)
    effectiveMaxHeight = MIN(effectiveMaxHeight, maxHeight);

    MMLogInfo(@"Applying max window height limit for Main Window: %.0f%% of %.0f = %.0f (effective: %.0f)", (CGFloat)percentage, maxHeight, calculatedMaxHeight, effectiveMaxHeight);

    return CGSizeMake(maxWidth, effectiveMaxHeight);
}


- (CGFloat)inputViewMinHeight:(EZWindowType)type {
    if (![self showInputTextField:type]) {
        return 0;
    }

    switch (type) {
        case EZWindowTypeMain:
            return 75; // three line
        case EZWindowTypeFixed:
            return 65; // > two line
        case EZWindowTypeMini:
            return 54; // two line.
        default:
            return 54; // two line
    }
}

- (CGFloat)inputViewMaxHeight:(EZWindowType)type {
    if (![self showInputTextField:type]) {
        return 0;
    }

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

    CGRect windowFrame = window.frame;

    // Record floating window frame
    [Configuration.shared setWindowFrame:windowFrame windowType:windowType];

    switch (windowType) {
        case EZWindowTypeMain:
            self.mainWindowFrame = windowFrame;
            break;
        case EZWindowTypeFixed: {
            self.fixedWindowFrame = windowFrame;

            // Record screenVisibleFrame when fixedWindowPosition is EZShowWindowPositionFormer
            if (Configuration.shared.fixedWindowPosition == EZShowWindowPositionFormer) {
                CGPoint fixedWindowCenter = NSMakePoint(NSMidX(windowFrame), NSMidY(windowFrame));

                // Update lastPoint to update current active screen
                EZWindowManager.shared.lastPoint = fixedWindowCenter;
                Configuration.shared.formerFixedScreenVisibleFrame = self.screen.visibleFrame;
            }
            break;
        }
        case EZWindowTypeMini:
            self.miniWindowFrame = window.frame;

            if (Configuration.shared.miniWindowPosition == EZShowWindowPositionFormer) {
                CGPoint fixedWindowCenter = NSMakePoint(NSMidX(windowFrame), NSMidY(windowFrame));

                EZWindowManager.shared.lastPoint = fixedWindowCenter;
                Configuration.shared.formerMiniScreenVisibleFrame = self.screen.visibleFrame;
            }
            break;
        default:
            break;
    }
}

- (BOOL)showInputTextField:(EZWindowType)windowType {
    return [Configuration.shared showInputTextFieldWithKey:WindowConfigurationKeyInputFieldCellVisible windowType:windowType];
}

- (void)updateScreen:(NSScreen *)screen {
    _screen = screen;

//    MMLogInfo(@"update screen: %@", @(screen.visibleFrame));

    [self setupMaximumWindowSize:screen];
}

- (void)updateScreenVisibleFrame:(CGRect)visibleFrame {
   _screenVisibleFrame = visibleFrame;
}

@end
