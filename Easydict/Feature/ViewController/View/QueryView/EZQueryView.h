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

NS_ASSUME_NONNULL_BEGIN

static CGFloat const EZExceptInputViewHeight = EZAudioButtonWidth_26 + EZAudioButtonBottomOffset_5; //31;
static NSTimeInterval const EZDelayDetectTextLanguageInterval = 1.0;

@interface EZQueryView : NSView

@property (nonatomic, strong) EZQueryModel *queryModel;
@property (nonatomic, strong) EZTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) EZLoadingAnimationView *loadingAnimationView;
@property (nonatomic, strong) NSTextField *alertTextField;

@property (nonatomic, assign) BOOL enableAutoDetect;
@property (nonatomic, assign) BOOL clearButtonHidden;
@property (nonatomic, assign) BOOL isTypingChinese;

@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);

@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSButton *button);
@property (nonatomic, copy) void (^clearBlock)(NSString *text);

@property (nonatomic, copy) void (^updateQueryTextBlock)(NSString *text, CGFloat queryViewHeight);
@property (nonatomic, copy) void (^selectedLanguageBlock)(EZLanguage language);


- (CGFloat)heightOfQueryView;

- (void)initializeAimatedButtonAlphaValue:(EZQueryModel *)queryModel;

- (void)startLoadingAnimation:(BOOL)isLoading;

- (void)showAlertMessage:(NSString *)message;

- (void)showAutoDetectLanguage:(BOOL)showFlag;

/// Highlight all links in textstorage
- (void)highlightAllLinks;

@end

NS_ASSUME_NONNULL_END
