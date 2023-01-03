//
//  EDQueryView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTextView.h"
#import "EZQueryModel.h"
#import "NSView+EZWindowType.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat EZExceptInputViewHeight = 30;

@interface EZQueryView : NSTableRowView

@property (nonatomic, strong) EZQueryModel *queryModel;

@property (nonatomic, strong) EZTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;


@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);

@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSButton *button);
@property (nonatomic, copy) void (^clearBlock)(NSString *text);

@property (nonatomic, copy) void (^updateQueryTextBlock)(NSString *text, CGFloat queryViewHeight);
@property (nonatomic, copy) void (^selectedLanguageBlock)(EZLanguage language);


- (CGFloat)heightOfQueryView;

- (void)setClearButtonAnimatedHidden:(BOOL)show;

- (void)initializeAimatedButtonAlphaValue:(EZQueryModel *)queryModel;

@end

NS_ASSUME_NONNULL_END
