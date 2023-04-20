//
//  EZWindowFrameManager.h
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZBaseQueryWindow;

NS_ASSUME_NONNULL_BEGIN

/// Window type
typedef NS_ENUM(NSInteger, EZWindowType) {
    EZWindowTypeNone = -1,
    EZWindowTypeMain = 0,
    EZWindowTypeMini = 1,
    EZWindowTypeFixed = 2,
};

/// Show window position
typedef NS_ENUM(NSUInteger, EZShowWindowPosition) {
    EZShowWindowPositionRight = 0,
    EZShowWindowPositionMouse = 1,
    EZShowWindowPositionFormer = 2,
};

/// Avoid window manager and base window recycling retain.
@interface EZLayoutManager : NSObject

@property (nonatomic, assign) CGRect miniWindowFrame;
@property (nonatomic, assign) CGRect fixedWindowFrame;
@property (nonatomic, assign) CGRect mainWindowFrame;


+ (instancetype)shared;

- (CGSize)minimumWindowSize:(EZWindowType)type;
- (CGSize)maximumWindowSize:(EZWindowType)type;

- (CGRect)windowFrameWithType:(EZWindowType)type;
- (CGRect)windowFrame:(EZBaseQueryWindow *)window;

- (CGFloat)inputViewMinHeight:(EZWindowType)type;
- (CGFloat)inputViewMaxHeight:(EZWindowType)type;

- (void)updateWindowFrame:(EZBaseQueryWindow *)window;
- (NSString *)windowName:(EZWindowType)type;

- (MMOrderedDictionary<NSNumber *, NSString *> *)fixedWindowPositionDict;

@end

NS_ASSUME_NONNULL_END
