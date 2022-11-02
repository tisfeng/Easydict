//
//  ResultView.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "ResultView.h"

#define kMargin 10


@interface ResultView ()

@property (nonatomic, strong) MASConstraint *actionButtonBottomConstraint;
@property (nonatomic, copy) void (^actionBlock)(void);

@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *typeImageView;
@property (nonatomic, strong) NSTextField *typeLabel;
@property (nonatomic, strong) NSImageView *disableImageView;

@property (nonatomic, strong) NSButton *arrowButton;

@end


@implementation ResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        [self.layer excuteLight:^(id _Nonnull x) {
            [x setBackgroundColor:LightBgColor.CGColor];
        } drak:^(id _Nonnull x) {
            [x setBackgroundColor:DarkBgColor.CGColor];
        }];
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        self.topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
            [self addSubview:view];
            view.wantsLayer = YES;
            view.layer.backgroundColor = DarkBarBgColor.CGColor;
            
            [view.layer excuteLight:^(CALayer *layer) {
                layer.backgroundColor = LightBarBgColor.CGColor;
            } drak:^(CALayer *layer) {
                layer.backgroundColor = DarkBarBgColor.CGColor;
            }];
            
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.equalTo(self);
                make.height.mas_equalTo(25);
            }];
        }];
        
        CGSize iconSize = CGSizeMake(15, 15);
        
        self.typeImageView = [NSImageView mm_make:^(NSImageView *imageView) {
            [self addSubview:imageView];    
            [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.topBarView).offset(kMargin);
                make.centerY.equalTo(self.topBarView);
                make.size.mas_equalTo(iconSize);
            }];
        }];
        
        self.typeLabel = [NSTextField mm_make:^(NSTextField *label) {
            [self addSubview:label];
            label.editable = NO;
            label.bordered = NO;
            label.backgroundColor = NSColor.clearColor;
            label.alignment = NSTextAlignmentCenter;
            NSString *title = @"系统翻译";
            label.attributedStringValue = [[NSAttributedString alloc] initWithString:title];
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.typeImageView.mas_right).offset(5);
                make.centerY.equalTo(self.topBarView).offset(-1);
            }];
        }];
        
        self.disableImageView = [NSImageView mm_make:^(NSImageView *imageView) {
            [self addSubview:imageView];
            NSImage *image = [NSImage imageNamed:@"disabled"];
            [imageView setImage:image];
            
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.typeLabel.mas_right).offset(5);
                make.centerY.equalTo(self.topBarView);
                make.size.mas_equalTo(iconSize);
            }];
        }];
        
        self.arrowButton = [NSButton mm_make:^(NSButton *_Nonnull button) {
            [self addSubview:button];
            button.wantsLayer = YES;
            button.layer.cornerRadius = 3;
            button.bordered = NO;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            button.image = [NSImage imageNamed:@"arrow-down-slim"];
            button.imageScaling = NSImageScaleAxesIndependently;
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.topBarView.mas_right).offset(-kMargin);
                make.centerY.equalTo(self.topBarView);
                make.size.mas_equalTo(CGSizeMake(20, 20));
            }];
            mm_weakify(self)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
                mm_strongify(self)
                NSLog(@"点击 arrowButton");
                if (self.actionBlock) {
                    void (^block)(void) = self.actionBlock;
                    block();
                }
                return RACSignal.empty;
            }]];
        }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSTrackingArea *playTrackingArea = [[NSTrackingArea alloc]
                                                initWithRect:[self.arrowButton bounds]
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                owner:self
                                                userInfo:nil];
            [self.arrowButton addTrackingArea:playTrackingArea];
        });
        

        self.normalResultView = [NormalResultView new];
        self.wordResultView = [WordResultView new];
        self.stateTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.font = [NSFont systemFontOfSize:14];
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:LightTextColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.topBarView.mas_bottom).offset(kMargin);
                make.left.offset(kMargin);
                make.right.lessThanOrEqualTo(self).offset(-kMargin);
                make.bottom.lessThanOrEqualTo(self).offset(-kMargin);
            }];
        }];
        self.actionButton = [NSButton mm_make:^(NSButton *_Nonnull button) {
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
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
                mm_strongify(self)
                NSLog(@"点击 action");
                if (self.actionBlock) {
                    void (^block)(void) = self.actionBlock;
                    block();
                }
                return RACSignal.empty;
            }]];
        }];
    }
    return self;
}

- (void)mouseEntered:(NSEvent *)theEvent {
    CGPoint point = theEvent.locationInWindow;
    point = [self convertPoint:point fromView:nil];
    
    [self excuteLight:^(id x) {
        NSColor *highlightBgColor = [NSColor mm_colorWithHexString:@"#E2E2E2"];
        [self hightlightCopyButtonBgColor:highlightBgColor point:point];
    } drak:^(id x) {
        [self hightlightCopyButtonBgColor:DarkBorderColor point:point];
    }];
}

- (void)hightlightCopyButtonBgColor:(NSColor *)color point:(CGPoint)point {
    if (CGRectContainsPoint(self.arrowButton.frame, point)) {
        [[self.arrowButton cell] setBackgroundColor:color];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [[self.arrowButton cell] setBackgroundColor:NSColor.clearColor];
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
            make.top.equalTo(self.topBarView.mas_bottom);
            make.left.right.bottom.equalTo(self);
        }];
        [self.wordResultView refreshWithResult:result];
    } else {
        // 显示普通的
        [self.wordResultView removeFromSuperview];
        self.wordResultView.hidden = YES;
        
        [self addSubview:self.normalResultView];
        self.normalResultView.hidden = NO;
        [self.normalResultView refreshWithStrings:result.normalResults];
        [self.normalResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topBarView.mas_bottom);
            make.left.right.bottom.equalTo(self);
        }];
    }
}

- (void)refreshWithStateString:(NSString *)string {
    [self refreshWithStateString:string actionTitle:nil action:nil];
}

- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action {
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
    } else {
        self.actionButton.hidden = YES;
        self.actionBlock = nil;
        [self.actionButtonBottomConstraint uninstall];
    }
}

@end
