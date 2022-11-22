//
//  EZWindowFrameManager.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZBaseQueryWindow;

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, EZWindowType) {
    EZWindowTypeMain = 0,
    EZWindowTypeMini = 1,
    EZWindowTypeFixed = 2,
};


/// Avoid window manager and base window recycling retain.
@interface EZWindowFrameManager : NSObject

@property (nonatomic, assign) CGFloat miniWindowWidth; // 300
@property (nonatomic, assign) CGFloat miniWindowHeight; // 200
@property (nonatomic, assign) CGFloat maxWindowHeight; // 

@property (nonatomic, assign) CGFloat inputViewMiniHeight; // 30, or 60
@property (nonatomic, assign) CGFloat inputViewMaxHeight; //

@property (nonatomic, assign) CGRect miniWindowFrame;
@property (nonatomic, assign) CGRect fixedWindowFrame;
@property (nonatomic, assign) CGRect mainWindowFrame;

+ (instancetype)shared;

- (CGRect)windowFrameWithType:(EZWindowType)type;
- (CGRect)windowFrame:(EZBaseQueryWindow *)window;

- (CGFloat)getInputViewMiniHeight:(EZWindowType)type;

@end

NS_ASSUME_NONNULL_END
