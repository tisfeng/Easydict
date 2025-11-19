//
//  MainTabViewController.h
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZLayoutManager.h"
#import "EZQueryModel.h"
#import "EZQueryResult.h"
#import "EZTitlebar.h"
#import "EZTableTipsCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZBaseQueryViewController : NSViewController

@property (nonatomic, copy) NSString *inputText;

@property (nonatomic, strong, readonly) EZQueryModel *queryModel;

@property (nonatomic, assign) EZWindowType windowType;
@property (nullable, nonatomic, weak) EZBaseQueryWindow *baseQueryWindow;

@property (nonatomic, strong, readonly) NSArray<EZQueryService *> *services;

@property (nonatomic, copy) void (^resizeWindowBlock)(void);

- (instancetype)initWithWindowType:(EZWindowType)type;

- (void)resetTableView:(nullable void (^)(void))completion;

- (void)startQueryText:(nullable NSString *)text actionType:(EZActionType)actionType;
- (void)startOCRImage:(NSImage *)image actionType:(EZActionType)actionType autoQuery:(BOOL)autoQuery;

- (void)retryQueryWithLanguage:(EZLanguage)language;

- (void)clearInput;
- (void)clearAll;

- (void)copyQueryText;

- (void)copyFirstTranslatedText;

- (void)toggleTranslationLanguages;

- (void)focusInputTextView;

- (void)stopPlayingQueryText;
- (void)togglePlayQueryText;
- (void)togglePlayQueryText:(BOOL)playFlag;

/// Detect query text, and update select language cell.
- (void)detectQueryText:(nullable void (^)(NSString *language))completion;

/// Update query text, auto adjust ParagraphStyle.
- (void)updateQueryTextAndParagraphStyle:(NSString *)text actionType:(EZActionType)actionType;

- (void)scrollToEndOfTextView;

- (void)updateCellWithResult:(EZQueryResult *)result reloadData:(BOOL)reloadData;

- (void)disableReplaceTextButton;

- (void)receiveTitlebarAction:(EZTitlebarQuickAction)action;

- (void)updateActionType:(EZActionType)actionType;

/// show tips view
- (void)showTipsView:(BOOL)isVisible;

@end

NS_ASSUME_NONNULL_END
