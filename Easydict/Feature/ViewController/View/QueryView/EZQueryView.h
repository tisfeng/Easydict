//
//  EDQueryView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTextView.h"
#import "EZQueryModel.h"
#import "NSObject+EZWindowType.h"
#import "EZLoadingAnimationView.h"
#import "EZAudioButton.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat const EZQueryViewExceptInputViewHeight = EZAudioButtonWidthHeight_24 + EZAudioButtonInputViewTopPadding_4 + EZAudioButtonBottomMargin_4; // 32;

static NSTimeInterval const EZDelayDetectTextLanguageInterval = 1.0;

@interface EZQueryView : NSView

@property (nonatomic, strong) EZQueryModel *queryModel;
@property (nonatomic, strong) EZTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) EZLoadingAnimationView *loadingAnimationView;
@property (nonatomic, copy) NSString *placeholderText;
@property (nonatomic, copy) NSString *alertText;

@property (nonatomic, strong) EZAudioButton *audioButton;

@property (nonatomic, assign) BOOL clearButtonHidden;
@property (nonatomic, assign) BOOL isTypingChinese;

@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);

@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSButton *button);
@property (nonatomic, copy) void (^clearBlock)(NSString *text);
@property (nonatomic, copy) void (^pasteTextBlock)(NSString *text);

@property (nonatomic, copy) void (^updateInputTextBlock)(NSString *text, CGFloat queryViewHeight);
@property (nonatomic, copy) void (^selectedLanguageBlock)(EZLanguage language);


- (CGFloat)heightOfQueryView;

- (void)initializeAimatedButtonAlphaValue:(EZQueryModel *)queryModel;

- (void)startLoadingAnimation:(BOOL)isLoading;
- (void)setAlertTextHidden:(BOOL)hidden;

/// Highlight all links in textstorage
- (void)highlightAllLinks;

/// Remove all links in textstorage.
- (void)removeAllLinks;

- (void)scrollToEndOfTextView;

@end

NS_ASSUME_NONNULL_END
