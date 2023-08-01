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

@property (nonatomic, copy) void (^queryTextBlock)(NSString *word);

@property (nonatomic, copy) void (^updateViewHeightBlock)(CGFloat viewHeight);

@property (nonatomic, copy) void (^didFinishLoadingHTMLBlock)(void);

- (void)refreshWithResult:(EZQueryResult *)result;

@end

NS_ASSUME_NONNULL_END
