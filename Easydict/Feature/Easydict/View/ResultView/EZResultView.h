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

@property (nonatomic, strong) EZQueryResult *result;

@property (nonatomic, copy) void (^clickArrowBlock)(BOOL isShowing);

@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);

- (void)refreshWithResult:(EZQueryResult *)result;
- (void)refreshWithStateString:(NSString *)string;
- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action;

@end

NS_ASSUME_NONNULL_END
