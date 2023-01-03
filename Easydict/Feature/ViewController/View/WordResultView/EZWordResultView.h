//
//  EZCommonResultView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZWordResultView : NSView

@property (nonatomic, copy, readonly) NSString *copiedText;

@property (nonatomic, assign, readonly) CGFloat viewHeight;

@property (nonatomic, copy) void (^playAudioBlock)(EZWordResultView *view, NSString *word);
@property (nonatomic, copy) void (^copyTextBlock)(EZWordResultView *view, NSString *word);
@property (nonatomic, copy) void (^clickTextBlock)(EZWordResultView *view, NSString *word);

- (void)refreshWithResult:(EZQueryResult *)result;

@end

NS_ASSUME_NONNULL_END
