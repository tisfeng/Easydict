//
//  ResultView.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "ResultView.h"

#define kMargin 12.0

@interface ResultView ()

@property (nonatomic, strong) MASConstraint *actionButtonBottomConstraint;
@property (nonatomic, copy) void(^actionBlock)(void);

@end

@implementation ResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        [self.layer excuteLight:^(id  _Nonnull x) {
            [x setBackgroundColor:[NSColor mm_colorWithHexString:@"#EEEEEE"].CGColor];
        } drak:^(id  _Nonnull x) {
            [x setBackgroundColor:DarkGrayColor.CGColor];
        }];
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
        self.normalResultView = [NormalResultView new];
        self.wordResultView = [WordResultView new];
        self.stateTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField * _Nonnull textField) {
            [self addSubview:textField];
            textField.font = [NSFont systemFontOfSize:14];
            [textField excuteLight:^(id  _Nonnull x) {
                [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
            } drak:^(id  _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.offset(kMargin);
                make.left.offset(kMargin);
                make.right.lessThanOrEqualTo(self).offset(-kMargin);
                make.bottom.lessThanOrEqualTo(self).offset(-kMargin);
            }];
        }];
        self.actionButton = [NSButton mm_make:^(NSButton * _Nonnull button) {
            [self addSubview:button];
            button.hidden = YES;
            button.bordered = NO;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.stateTextField.mas_bottom).offset(5);
                make.left.equalTo(self.stateTextField.mas_left).offset(-2);
                self.actionButtonBottomConstraint = make.bottom.lessThanOrEqualTo(self).offset(-kMargin);
            }];
            mm_weakify(self)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
                mm_strongify(self)
                NSLog(@"点击 action");
                if (self.actionBlock) {
                    void(^block)(void) = self.actionBlock;
                    block();
                }
                return RACSignal.empty;
            }]];
        }];
    }
    return self;
}

- (void)refreshWithResult:(TranslateResult *)result {
    self.stateTextField.hidden = YES;
    self.stateTextField.stringValue = @"";
    self.actionButton.hidden = YES;
    self.actionButton.attributedTitle = [NSAttributedString new];

    if (result.wordResult) {
        // 显示word
        [self.normalResultView removeFromSuperview];
        self.normalResultView.hidden = YES;
        
        [self addSubview:self.wordResultView];
        self.wordResultView.hidden = NO;
        [self.wordResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.inset(0);
        }];
        [self.wordResultView refreshWithResult:result];
    }else {
        // 显示普通的
        [self.wordResultView removeFromSuperview];
        self.wordResultView.hidden = YES;
        
        [self addSubview:self.normalResultView];
        self.normalResultView.hidden = NO;
        [self.normalResultView refreshWithStrings:result.normalResults];
        [self.normalResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.inset(0);
        }];
    }
}

- (void)refreshWithStateString:(NSString *)string {
    [self refreshWithStateString:string actionTitle:nil action:nil];
}

- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString * _Nullable)actionTitle action:(void (^ _Nullable)(void))action {
    [self.normalResultView removeFromSuperview];
    self.normalResultView.hidden = YES;
    [self.wordResultView removeFromSuperview];
    self.wordResultView.hidden = YES;
    
    self.stateTextField.hidden = NO;
    self.stateTextField.stringValue = string;
    if (actionTitle.length) {
        self.actionButton.hidden = NO;
        self.actionButton.attributedTitle = [NSAttributedString mm_attributedStringWithString:actionTitle font:[NSFont systemFontOfSize:14] color:[NSColor mm_colorWithHexString:@"#007AFF"]];
        self.actionBlock = action;
        [self.actionButtonBottomConstraint install];
    }else {
        self.actionButton.hidden = YES;
        self.actionBlock = nil;
        [self.actionButtonBottomConstraint uninstall];
    }
}

@end
