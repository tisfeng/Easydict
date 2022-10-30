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

@interface ResultView : NSView

@property (nonatomic, strong) NormalResultView *normalResultView;
@property (nonatomic, strong) WordResultView *wordResultView;
@property (nonatomic, strong) NSTextField *stateTextField;
@property (nonatomic, strong) NSButton *actionButton;

- (void)refreshWithResult:(TranslateResult *)result;
- (void)refreshWithStateString:(NSString *)string;
- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString * _Nullable)actionTitle action:(void (^ _Nullable )(void))action;

@end

NS_ASSUME_NONNULL_END
