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

NS_ASSUME_NONNULL_BEGIN

@interface EZBaseQueryViewController : NSViewController

@property (nonatomic, copy) NSString *queryText;

@property (nonatomic, assign) EZWindowType windowType;
@property (nonatomic, weak) EZBaseQueryWindow *window;

@property (nonatomic, copy) void (^resizeWindowBlock)(void);

- (instancetype)initWithWindowType:(EZWindowType)type;

- (void)resetTableView:(void (^)(void))completion;

- (void)startQueryText:(nullable NSString *)text actionType:(EZActionType)actionType;
- (void)startQueryWithImage:(NSImage *)image;

- (void)startOCRImage:(NSImage *)image actionType:(EZActionType)actionType completion:(nullable void (^)(NSString *ocrText))completion;

- (void)retryQuery;

- (void)clearInput;
- (void)clearAll;

- (void)toggleTranslationLanguages;

- (void)focusInputTextView;

- (void)playQueryTextSound;

/// Detect query text, and update select language cell.
- (void)detectQueryText:(nullable void (^)(void))completion;

/// Update query text, auto adjust ParagraphStyle.
- (void)updateQueryTextAndParagraphStyle:(NSString *)text actionType:(EZActionType)actionType;

- (void)scrollToEndOfTextView;

@end

NS_ASSUME_NONNULL_END
