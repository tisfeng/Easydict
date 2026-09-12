//
//  EZTitlebar.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZOpenLinkButton.h"

NS_ASSUME_NONNULL_BEGIN

@class WordbookStarHost;

typedef NS_ENUM(NSUInteger, EZTitlebarQuickAction) {
    EZTitlebarQuickActionRemoveCommentBlockSymbols,
    EZTitlebarQuickActionWordsSegmentation,
    EZTitlebarQuickActionReplaceNewlineWithSpace,
};

typedef void(^EZTitlebarQuickActionBlock)(EZTitlebarQuickAction);

@interface EZTitlebar : NSView

@property (nonatomic, assign) BOOL pin;

@property (nonatomic, strong) EZOpenLinkButton *pinButton;

@property (nonatomic, strong) EZOpenLinkButton *eudicButton;
@property (nonatomic, strong) EZOpenLinkButton *googleButton;
@property (nonatomic, strong) EZOpenLinkButton *appleDictionaryButton;

@property (nonatomic, strong) EZOpenLinkButton *quickActionButton;
@property (nonatomic, strong) WordbookStarHost *wordbookHost;

@property (nonatomic, copy) EZTitlebarQuickActionBlock menuActionBlock;

- (void)updateShortcutButtonsToolTip;
- (void)refreshWordbookButton;

@end

NS_ASSUME_NONNULL_END
