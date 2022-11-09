//
//  EZResultView.h
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZCommonView.h"
#import "WordResultView.h"
#import "TranslateResult.h"

NS_ASSUME_NONNULL_BEGIN

//static const CGFloat kResultViewMiniHeight = 25;

@interface EZResultView : EZCommonView

@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, copy) NSString *copiedText;

//@property (nonatomic, strong) WordResultView *wordResultView;
//@property (nonatomic, strong) NSTextField *stateTextField;
//@property (nonatomic, strong) NSButton *actionButton;

@property (nonatomic, copy) void (^playAudioBlock)( NSString *url);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);

- (void)refreshWithResult:(TranslateResult *)result;
- (void)refreshWithStateString:(NSString *)string;
- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action;

@end

NS_ASSUME_NONNULL_END
