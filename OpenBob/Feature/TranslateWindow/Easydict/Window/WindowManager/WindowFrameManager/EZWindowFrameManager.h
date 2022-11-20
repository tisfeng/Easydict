//
//  EZWindowFrameManager.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "EZBaseQueryWindow.h"

@class EZBaseQueryWindow;

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, EZWindowType) {
    EZWindowTypeMain = 0,
    EZWindowTypeMini = 1,
    EZWindowTypeFixed = 2,
};


@interface EZWindowFrameManager : NSObject

@property (nonatomic, assign) CGRect miniWindowFrame;
@property (nonatomic, assign) CGRect fixedWindowFrame;
@property (nonatomic, assign) CGRect mainWindowFrame;

+ (instancetype)shared;

- (CGRect)windowFrameWithType:(EZWindowType)type;
- (CGRect)windowFrame:(EZBaseQueryWindow *)window;

@end

NS_ASSUME_NONNULL_END
