//
//  MainTabViewController.h
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZLayoutManager.h"
#import "EZTitlebar.h"
#import "EZTableTipsCell.h"
#import "EZLanguageModel.h"

@class EZQueryModel;
@class EZQueryResult;
@class EZQueryService;

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

/// Recreate the query model and rebind dependent managers for background OCR.
- (void)resetQueryModelForBackgroundOCR;

- (void)startQueryText:(nullable NSString *)text actionType:(EZActionType)actionType;

/// Prepare a saved query's text and language pair without updating global defaults.
- (void)prepareReplayQueryText:(NSString *)text
                sourceLanguage:(EZLanguage)sourceLanguage
                targetLanguage:(EZLanguage)targetLanguage
                    actionType:(EZActionType)actionType;

- (void)startOCRImage:(NSImage *)image actionType:(EZActionType)actionType autoQuery:(BOOL)autoQuery;

- (void)retryQueryWithLanguage:(EZLanguage)language;

- (void)clearInput;
- (void)clearAll;

- (void)copyQueryText;

- (void)copyFirstTranslatedText;

/// Returns the translated text of the first service result, if available.
- (nullable NSString *)firstTranslatedText;

- (void)toggleTranslationLanguages;

- (void)focusInputTextView;

/// Cancel the pending auto-query-while-typing debounce.
- (void)cancelAutoQuery;

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

/// Discard cached dictionary WebViews when the query window has been idle.
- (void)discardDictionaryWebViews;

/// show tips view
- (void)showTipsView:(BOOL)isVisible;

@end

NS_ASSUME_NONNULL_END
