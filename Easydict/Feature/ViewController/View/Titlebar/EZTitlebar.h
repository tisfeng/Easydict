//
//  EZTitlebar.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZHoverButton.h"
#import "EZOpenLinkButton.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EZTitlebarAction) {
    EZTitlebarActionRemoveCommentBlockSymbols,
    EZTitlebarActionWordsSegmentation,
};

typedef void(^EZTitlebarActionBlock)(EZTitlebarAction);

@interface EZTitlebar : NSView

@property (nonatomic, assign) BOOL pin;

@property (nonatomic, strong) EZOpenLinkButton *pinButton;

@property (nonatomic, strong) EZOpenLinkButton *eudicButton;
@property (nonatomic, strong) EZOpenLinkButton *googleButton;
@property (nonatomic, strong) EZOpenLinkButton *appleDictionaryButton;

@property (nonatomic, strong) EZOpenLinkButton *favoriteButton;

@property (nonatomic, strong) EZOpenLinkButton *quickActionButton;

@property (nonatomic, copy) EZTitlebarActionBlock menuActionBlock;

@end

NS_ASSUME_NONNULL_END
