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

@property (nonatomic, strong) NSMutableArray *floatingWindowTypeArray;
@property (nonatomic, assign) EZWindowType floatingWindowType;
@property (nonatomic, strong, nullable) EZBaseQueryWindow *floatingWindow;

/// Right-bottom offset: (15, -12)
@property (nonatomic, assign) CGPoint offsetPoint;


+ (instancetype)shared;

- (EZBaseQueryWindow *)windowWithType:(EZWindowType)type;

- (void)inputTranslate;
- (void)selectTextTranslate;
- (void)snipTranslate;
- (void)showMiniFloatingWindow;
- (void)screenshotOCR;

// TODO: need to clean close window methods.
- (void)closeWindow;

- (void)closeFloatingWindow;

/// Close floating window, except main window.
- (void)closeFloatingWindowExceptMain;

- (void)rerty;

- (void)clearInput;
- (void)clearAll;

/// Pin window, or cancel pin.
- (void)pin;
- (void)hide;

- (void)toggleTranslationLanguages;

- (void)focusInputTextView;

- (void)playQueryTextSound;

- (void)activeLastFrontmostApplication;

- (void)showOrHideDockAppAndMainWindow;
- (void)showMainWindow:(BOOL)showFlag;

- (void)updatePopButtonQueryAction;

- (void)updateFloatingWindowType:(EZWindowType)floatingWindowType;

@end

NS_ASSUME_NONNULL_END
