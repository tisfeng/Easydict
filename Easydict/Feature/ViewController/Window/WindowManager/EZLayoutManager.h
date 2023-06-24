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

@property (nonatomic, strong) NSScreen *screen;


+ (instancetype)shared;

- (CGSize)minimumWindowSize:(EZWindowType)type;
- (CGSize)maximumWindowSize:(EZWindowType)type;

- (CGRect)windowFrameWithType:(EZWindowType)type;
- (CGRect)windowFrame:(EZBaseQueryWindow *)window;

- (CGFloat)inputViewMinHeight:(EZWindowType)type;
- (CGFloat)inputViewMaxHeight:(EZWindowType)type;

- (void)updateWindowFrame:(EZBaseQueryWindow *)window;

//- (NSString *)windowName:(EZWindowType)type;

//- (MMOrderedDictionary<NSNumber *, NSString *> *)fixedWindowPositionDict;

@end

NS_ASSUME_NONNULL_END
