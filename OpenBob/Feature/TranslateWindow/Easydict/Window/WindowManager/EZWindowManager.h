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
#import "EZWindowFrameManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface EZWindowManager : NSObject

@property (nonatomic, strong) EZMainQueryWindow *mainWindow;
@property (nonatomic, strong) EZPopButtonWindow *popWindow;
@property (nonatomic, strong, nullable) EZFixedQueryWindow *fixedWindow;
@property (nonatomic, strong, nullable) EZMiniQueryWindow *miniWindow;

@property (nonatomic, assign) EZWindowType showingWindowType;
//@property (nonatomic, assign) CGRect showingWindowFrame;

+ (instancetype)shared;

- (EZWindowType)getWindowType:(EZBaseQueryWindow *)window;
- (EZBaseQueryWindow *)windowWithType:(EZWindowType)type;

@end

NS_ASSUME_NONNULL_END
