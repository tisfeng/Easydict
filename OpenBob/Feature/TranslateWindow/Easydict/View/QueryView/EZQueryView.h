//
//  EDQueryView.h
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZCommonView.h"
#import "EZTextView.h"
#import "EZQueryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryView : EZCommonView

@property (nonatomic, strong) EZQueryModel *model;

@property (nonatomic, strong) EZTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;

@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSButton *button);

@property (nonatomic, assign) CGFloat textViewMiniHeight;

@property (nonatomic, copy) void (^updateQueryTextBlock)(NSString *text, CGFloat textViewHeight);

@end

NS_ASSUME_NONNULL_END
