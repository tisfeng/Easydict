//
//  ResultView.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "ResultView.h"
#import "ServiceTypes.h"
#import "EZHoverButton.h"

static const CGFloat kMargin = 10;

@interface ResultView ()

@property (nonatomic, strong) MASConstraint *actionButtonBottomConstraint;
@property (nonatomic, copy) void (^actionBlock)(void);

@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *typeImageView;
@property (nonatomic, strong) NSTextField *typeLabel;
@property (nonatomic, strong) NSImageView *disableImageView;

@property (nonatomic, strong) NSButton *arrowButton;

@property (nonatomic, strong) EZHoverButton *audioButton;
@property (nonatomic, strong) EZHoverButton *textCopyButton;

@property (nonatomic, copy) void (^audioActionBlock)(NSString *text);
@property (nonatomic, copy) void (^copyActionBlock)(NSString *text);

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
        self.layer.cornerRadius = 8;
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
                make.height.mas_equalTo(kResultViewMiniHeight);
            }];
        }];
        self.topBarView.mas_key = @"topBarView";
        
        CGSize iconSize = CGSizeMake(18, 18);
        
        self.typeImageView = [NSImageView mm_make:^(NSImageView *imageView) {
            [self addSubview:imageView];
            [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.topBarView).offset(kMargin);
                make.centerY.equalTo(self.topBarView);
                make.size.mas_equalTo(iconSize);
            }];
        }];
        self.typeImageView.mas_key = @"typeImageView";
        
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
                make.centerY.equalTo(self.topBarView).offset(0);
            }];
        }];
        self.typeLabel.mas_key = @"typeLabel";
        
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
        self.disableImageView.mas_key = @"disableImageView";
        
        self.arrowButton = [NSButton mm_make:^(NSButton *button) {
            [self addSubview:button];
            button.wantsLayer = YES;
            button.layer.cornerRadius = 3;
            button.bordered = NO;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            NSImage *image = [NSImage imageNamed:@"arrow-down-slim"];
            [button excuteLight:^(NSButton *button) {
                button.image = [image imageWithTintColor:NSColor.blackColor];
            } drak:^(NSButton *button) {
                button.image = [image imageWithTintColor:NSColor.whiteColor];
            }];
            
            button.imageScaling = NSImageScaleProportionallyDown;
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.topBarView.mas_right).offset(-8);
                make.centerY.equalTo(self.topBarView);
                make.size.mas_equalTo(iconSize);
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
        self.arrowButton.mas_key = @"arrowButton";
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            NSTrackingArea *playTrackingArea = [[NSTrackingArea alloc]
                                                initWithRect:[self.arrowButton bounds]
                                                options:NSTrackingMouseEnteredAndExited |
                                                NSTrackingActiveAlways
                                                owner:self
                                                userInfo:nil];
            [self.arrowButton addTrackingArea:playTrackingArea];
        });
        
        self.wordResultView = [[WordResultView alloc] initWithFrame:frame];
        self.wordResultView.mas_key = @"wordResultView";
        
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
        self.stateTextField.mas_key = @"stateTextField";
        
        self.actionButton = [NSButton mm_make:^(NSButton *_Nonnull button) {
            [self addSubview:button];
            button.hidden = YES;
            button.bordered = NO;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.stateTextField.mas_top).offset(0);
                make.left.equalTo(self.stateTextField.mas_left).offset(0);
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
        self.actionButton.mas_key = @"actionButton";
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
    _result = result;
    
    self.stateTextField.hidden = YES;
    self.stateTextField.stringValue = @"";
    self.actionButton.hidden = YES;
    self.actionButton.attributedTitle = [NSAttributedString new];
    
    EZServiceType serviceType = result.serviceType;
    NSString *imageName = [NSString stringWithFormat:@"%@ Translate", serviceType];
    self.typeImageView.image = [NSImage imageNamed:imageName];
    
    TranslateService *translate = [ServiceTypes serviceWithType:serviceType];
    self.typeLabel.attributedStringValue = [NSAttributedString mm_attributedStringWithString:translate.name font:[NSFont systemFontOfSize:12]];
    
    // 显示word
    [self.normalResultView removeFromSuperview];
    self.normalResultView.hidden = YES;
    
    [self addSubview:self.wordResultView];
    self.wordResultView.hidden = NO;
    [self.wordResultView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self);
    }];
    [self.wordResultView refreshWithResult:result];
}

- (void)refreshWithStateString:(NSString *)string {
    [self refreshWithStateString:string actionTitle:nil action:nil];
}

- (void)refreshWithStateString:(NSString *)string actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action {
    _copiedText = string;
    
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
