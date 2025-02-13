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

@property (nonatomic, strong, nullable) EZMainQueryWindow *mainWindow;
@property (nonatomic, strong) EZPopButtonWindow *popButtonWindow;
@property (nonatomic, strong, nullable) EZFixedQueryWindow *fixedWindow;
@property (nonatomic, strong, nullable) EZMiniQueryWindow *miniWindow;

@property (nonatomic, strong) NSMutableArray *floatingWindowTypeArray;
@property (nonatomic, assign) EZWindowType floatingWindowType;
@property (nonatomic, strong, nullable) EZBaseQueryWindow *floatingWindow;

@property (nonatomic, strong) EZBaseQueryViewController *backgroundQueryViewController;

/// Right-bottom offset: (15, -12)
@property (nonatomic, assign) CGPoint offsetPoint;

@property (nonatomic, strong, readonly) NSScreen *screen;

@property (nonatomic, assign, readonly) CGPoint lastPoint;

+ (instancetype)shared;


#pragma mark - Menu Actions, Global Shorcut

- (void)inputTranslate;
- (void)selectTextTranslate;
- (void)snipTranslate;
- (void)showMiniFloatingWindow;
- (void)screenshotOCR;

#pragma mark - Application Shorcut

- (void)clearInput;
- (void)clearAll;
- (void)focusInputTextView;
- (void)copyQueryText;
- (void)copyFirstTranslatedText;
- (void)playOrStopQueryTextAudio;
- (void)rerty;
- (void)toggleTranslationLanguages;

/// Pin window, or cancel pin.
- (void)pin;
- (void)closeWindowOrExitSreenshot;


#pragma mark - URL scheme

/// Show floating window.
- (void)showFloatingWindowType:(EZWindowType)windowType
                     queryText:(nullable NSString *)text
                     autoQuery:(BOOL)autoQuery
                    actionType:(EZActionType)actionType;

- (void)showFloatingWindowType:(EZWindowType)windowType
                     queryText:(nullable NSString *)text
                    actionType:(EZActionType)actionType
                       atPoint:(CGPoint)point
             completionHandler:(nullable void (^)(void))completionHandler;

- (void)orderFrontWindowAndFocusInputTextView:(EZBaseQueryWindow *)window;

- (void)detectQueryText:(NSString *)text completion:(nullable void (^)(NSString *language))completion;

#pragma mark -

- (nullable EZBaseQueryWindow *)windowWithType:(EZWindowType)type;

- (void)closeFloatingWindow;
- (void)closeFloatingWindow:(EZWindowType)windowType;
- (void)closeFloatingWindowIfNotPinnedOrMain;
- (void)closeFloatingWindowIfNotPinned:(EZWindowType)windowType exceptWindowType:(EZWindowType)exceptWindowType;

- (void)destroyMainWindow;
- (void)showMainWindowIfNeeded;

- (void)activeLastFrontmostApplication;

- (void)updatePopButtonQueryAction;

- (void)updateFloatingWindowType:(EZWindowType)floatingWindowType isShowing:(BOOL)isShowing;

- (void)updateWindowsTitlebarButtonsToolTip;

@end

NS_ASSUME_NONNULL_END
