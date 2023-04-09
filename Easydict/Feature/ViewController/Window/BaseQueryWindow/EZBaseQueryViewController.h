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

- (void)startQueryText:(nullable NSString *)text queyType:(EZQueryType)queryType;
- (void)startQueryWithImage:(NSImage *)image;

- (void)retryQuery;

- (void)clearInput;
- (void)clearAll;

- (void)toggleTranslationLanguages;

- (void)focusInputTextView;

- (void)playQueryTextSound;

@end

NS_ASSUME_NONNULL_END
