//
//  EZResultView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryResult.h"

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kResultViewMiniHeight = 30;

// ???: If don't inherit from NSTableRowView, NSTextField in cell cannot selectable.
@interface EZResultView : NSView

@property (nonatomic, strong) EZQueryResult *result;

@property (nonatomic, copy) void (^clickArrowBlock)(EZQueryResult *result);
@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);
@property (nonatomic, copy) void (^clickTextBlock)(NSString *word);

- (void)updateLoadingAnimation;

@end

NS_ASSUME_NONNULL_END
