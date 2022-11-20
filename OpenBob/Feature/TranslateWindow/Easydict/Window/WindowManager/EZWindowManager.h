//
//  EZWindowManager.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZPopButtonWindow.h"
#import "EZFixedQueryWindow.h"
#import "EZMainQueryWindow.h"
#import "EZMiniQueryWindow.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EZWindowType) {
    EZWindowTypeMain = 0,
    EZWindowTypeMini = 1,
    EZWindowTypeFixed = 2,
};

@interface EZWindowManager : NSObject

@property (nonatomic, strong) EZMainQueryWindow *mainWindow;
@property (nonatomic, strong) EZPopButtonWindow *popWindow;
@property (nonatomic, strong, nullable) EZFixedQueryWindow *fixedWindow;
@property (nonatomic, strong, nullable) EZMiniQueryWindow *miniWindow;

@property (nonatomic, assign) EZWindowType showingWindowType;
@property (nonatomic, assign) CGRect showingWindowFrame;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
