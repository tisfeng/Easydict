//
//  ResultView.h
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NormalResultView.h"
#import "WordResultView.h"
#import "TranslateResult.h"

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kResultViewMiniHeight = 25;

@interface ResultView : NSView

@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, copy) NSString *copiedText;


@property (nonatomic, strong) NormalResultView *normalResultView;
@property (nonatomic, strong) WordResultView *wordResultView;
@property (nonatomic, strong) NSTextField *stateTextField;
@property (nonatomic, strong) NSButton *actionButton;

@property (nonatomic, copy) void (^playAudioBlock)( NSString *url);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);

- (void)refreshWithResult:(TranslateResult *)result;
- (void)refreshWithStateString:(NSString *)string;
- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action;

@end

NS_ASSUME_NONNULL_END
