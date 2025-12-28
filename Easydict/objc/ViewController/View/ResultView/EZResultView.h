//
//  EZResultView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZWordResultView.h"

@class EZQueryResult;

NS_ASSUME_NONNULL_BEGIN

static const CGFloat EZResultViewMiniHeight = 30;

// ???: If don't inherit from NSTableRowView, NSTextField in cell cannot selectable.
@interface EZResultView : NSView

@property (nonatomic, strong) EZQueryResult *result;

@property (nonatomic, strong) EZWordResultView *wordResultView;


@property (nonatomic, copy) void (^clickArrowBlock)(EZQueryResult *result);
@property (nonatomic, copy) void (^retryBlock)(EZQueryResult *result);

@property (nonatomic, copy) void (^queryTextBlock)(NSString *word);

- (void)updateLoadingAnimation;

@end

NS_ASSUME_NONNULL_END
