//
//  EZResultView.h
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WordResultView.h"
#import "EZQueryResult.h"

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kResultViewMiniHeight = 30;

@interface EZResultView : NSView

@property (nonatomic, copy) void (^clickArrowBlock)(EZQueryResult *result);

@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);
@property (nonatomic, copy) void (^queryTextBlock)(NSString *word);

- (void)refreshWithResult:(EZQueryResult *)result;

@end

NS_ASSUME_NONNULL_END
