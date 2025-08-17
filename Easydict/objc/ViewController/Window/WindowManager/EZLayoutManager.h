//
//  EZWindowFrameManager.h
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZEnumTypes.h"

@class EZBaseQueryWindow;

NS_ASSUME_NONNULL_BEGIN

/// Avoid window manager and base window recycling retain.
@interface EZLayoutManager : NSObject

@property (nonatomic, assign) CGRect miniWindowFrame;
@property (nonatomic, assign) CGRect fixedWindowFrame;
@property (nonatomic, assign) CGRect mainWindowFrame;

/// The screen where the last mouse click occurred, updated by EZWindowManager's lastPoint.
@property (nonatomic, strong, readonly) NSScreen *screen;

/// The screen frame when the floating window should be shown.
@property (nonatomic, readonly) CGRect screenVisibleFrame;


+ (instancetype)shared;

- (CGSize)minimumWindowSize:(EZWindowType)type;
- (CGSize)maximumWindowSize:(EZWindowType)type;

- (CGRect)windowFrameWithType:(EZWindowType)type;
- (CGRect)windowFrame:(EZBaseQueryWindow *)window;

- (CGFloat)inputViewMinHeight:(EZWindowType)type;
- (CGFloat)inputViewMaxHeight:(EZWindowType)type;

- (void)updateWindowFrame:(EZBaseQueryWindow *)window;

- (void)updateScreen:(NSScreen *)screen;

- (void)updateScreenVisibleFrame:(CGRect)visibleFrame;

@end

NS_ASSUME_NONNULL_END
