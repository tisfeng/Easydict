//
//  EZCommonResultView.h
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TranslateResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZWordResultView : NSView

@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, copy) void (^playAudioBlock)(EZWordResultView *view, NSString *word);
@property (nonatomic, copy) void (^copyTextBlock)(EZWordResultView *view, NSString *word);

//@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
//@property (nonatomic, copy) void (^copyActionBlock)(NSString *text);

- (void)refreshWithResult:(TranslateResult *)result;

@end

NS_ASSUME_NONNULL_END
