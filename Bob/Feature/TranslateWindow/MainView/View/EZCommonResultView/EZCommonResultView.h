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

@interface EZCommonResultView : NSView

@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, copy) void (^playAudioBlock)(EZCommonResultView *view, NSString *url);
@property (nonatomic, copy) void (^clickTextBlock)(EZCommonResultView *view, NSString *word);

- (void)refreshWithResult:(TranslateResult *)result;

@end

NS_ASSUME_NONNULL_END
