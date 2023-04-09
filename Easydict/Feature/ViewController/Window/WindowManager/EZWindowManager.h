//
//  EZWindowManager.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZPopButtonWindow.h"
#import "EZFixedQueryWindow.h"
#import "EZMainQueryWindow.h"
#import "EZMiniQueryWindow.h"
#import "EZLayoutManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZWindowManager : NSObject

@property (nonatomic, strong) EZMainQueryWindow *mainWindow;
@property (nonatomic, strong) EZPopButtonWindow *popButtonWindow;
@property (nonatomic, strong, nullable) EZFixedQueryWindow *fixedWindow;
@property (nonatomic, strong, nullable) EZMiniQueryWindow *miniWindow;

@property (nonatomic, assign) EZWindowType floatingWindowType;

@property (nonatomic, strong, nullable) EZBaseQueryWindow *floatingWindow;


+ (instancetype)shared;

- (EZBaseQueryWindow *)windowWithType:(EZWindowType)type;

- (void)inputTranslate;
- (void)selectTextTranslate;
- (void)snipTranslate;
- (void)showMiniFloatingWindow;

- (void)closeFloatingWindow;

/// Close floating window, except main window.
- (void)closeFloatingWindowExceptMain;

- (void)rerty;

- (void)activeLastFrontmostApplication;

- (void)showOrHideDockAppAndMainWindow;
- (void)showMainWindow:(BOOL)showFlag;

@end

NS_ASSUME_NONNULL_END
