//
//  WordResultView.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "WordResultView.h"
#import "ImageButton.h"
#import "NSColor+MyColors.h"
#import "EDButton.h"
#import "EDLabel.h"
#import "TextView.h"
#import "NSTextView+Height.h"
#import "MainWindow.h"

static const CGFloat kHorizontalMargin = 10;
static const CGFloat kVerticalMargin = 12;
static const CGFloat kVerticalPadding = 5;

/// wrappingLabel的约束需要偏移2,不知道是什么神设计
static const CGFloat kFixWrappingLabelMargin = 2;

@interface WordResultView ()

@property (nonatomic, strong) NSMutableArray<NSButton *> *audioButtons;

@property (nonatomic, strong) NSButton *audioButton;
@property (nonatomic, strong) NSButton *textCopyButton;

@property (nonatomic, copy) void (^audioActionBlock)(WordResultView *view);
@property (nonatomic, copy) void (^copyActionBlock)(WordResultView *view);

@property (nonatomic, strong) MASConstraint *textViewHeightConstraint;

@end


@implementation WordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _audioButtons = [NSMutableArray array];
    }
    return self;
}

- (void)refreshWithResult:(TranslateResult *)result {
    self.result = result;
    TranslateWordResult *wordResult = result.wordResult;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    __block NSView *lastView = nil;
    NSFont *textFont = [NSFont systemFontOfSize:14];
    NSFont *typeTextFont = [NSFont systemFontOfSize:13];
    NSColor *typeTextColor = [NSColor mm_colorWithHexString:@"#999999"];
    
    [wordResult.phonetics enumerateObjectsUsingBlock:^(TranslatePhonetic *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = obj.name;
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin);
                if (idx == 0) {
                    make.top.offset(kHorizontalMargin);
                } else {
                    make.top.equalTo(lastView.mas_bottom).offset(5);
                }
            }];
        }];
        nameTextFiled.mas_key = @"nameTextFiled_phonetics";
        
        // 部分没有音标文本
        NSTextField *valueTextField = nil;
        if (obj.value.length) {
            valueTextField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = [NSString stringWithFormat:@"[%@]", obj.value];
                [textField excuteLight:^(id _Nonnull x) {
                    [x setTextColor:NSColor.resultTextLightColor];
                } drak:^(id _Nonnull x) {
                    [x setTextColor:NSColor.resultTextDarkColor];
                }];
                textField.font = textFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(nameTextFiled.mas_right).offset(8);
                    make.centerY.equalTo(nameTextFiled);
                }];
            }];
            valueTextField.mas_key = @"valueTextField_phonetics";
        }
        
        EDButton *audioButton = [[EDButton alloc] init];
        [self addSubview:audioButton];
        [self.audioButtons addObject:audioButton];
        audioButton.bordered = NO;
        audioButton.imageScaling = NSImageScaleProportionallyDown;
        audioButton.bezelStyle = NSBezelStyleRegularSquare;
        [audioButton setButtonType:NSButtonTypeMomentaryChange];
        audioButton.image = [NSImage imageNamed:@"audio"];
        [audioButton excuteLight:^(id _Nonnull x) {
            audioButton.contentTintColor = NSColor.blackColor;
        } drak:^(id _Nonnull x) {
            audioButton.contentTintColor = NSColor.whiteColor;
        }];
        audioButton.toolTip = @"播放音频";
        [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left
                .equalTo(valueTextField ? valueTextField.mas_right : nameTextFiled.mas_right)
                .offset(6);
            make.centerY.equalTo(valueTextField ?: nameTextFiled);
            make.width.height.mas_equalTo(23);
        }];
        
        [audioButton setActionBlock:^(EDButton *_Nonnull button) {
            NSLog(@"click audioButton");
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                            initWithRect:audioButton.frame
                                            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                            owner:self
                                            userInfo:nil];
            [self addTrackingArea:trackingArea];
        });
        
        audioButton.mas_key = @"audioButton_phonetics";
        
        lastView = audioButton;
    }];
    
    if (result.normalResults.count) {
        NSTextField *typeTextField;
        
        if (result.wordResult) {
            typeTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = @"释义";
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.textColor = typeTextColor;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(10);
                    } else {
                        make.top.offset(kHorizontalMargin);
                    }
                    make.left.offset(kHorizontalMargin);
                    CGFloat width = [textField.attributedStringValue mm_getTextWidth];
                    make.width.mas_equalTo(width);
                }];
            }];
            typeTextField.mas_key = @"typeTextField_normalResults";
            
            [self layoutSubtreeIfNeeded];
        }
       
        NSString *text = [NSString mm_stringByCombineComponents:result.normalResults separatedString:@"\n"] ?: @"";

        
        EDLabel *resultLabel = [EDLabel new];
        [self addSubview:resultLabel];
        resultLabel.text = text;

       __block CGFloat leading = typeTextField.x;
        [resultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin);
            if (typeTextField) {
                make.top.equalTo(typeTextField).offset(0);
                CGFloat leftLeading = 0;
                make.left.equalTo(typeTextField.mas_right).offset(leftLeading);
                make.height.greaterThanOrEqualTo(@(15));
                leading += typeTextField.width + leftLeading;
            } else {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(10);
                } else {
                    make.top.offset(kVerticalMargin);
                }
                make.left.equalTo(self).offset(kHorizontalMargin);
            }
        }];
        resultLabel.mas_key = @"meanTextField_parts";

        [resultLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            CGFloat width = MainWindow.shared.width - leading;
            resultLabel.width = width;
            CGFloat height = [resultLabel getHeight];
            make.height.greaterThanOrEqualTo(@(height));
        }];

        lastView = resultLabel;
    }

    [wordResult.parts enumerateObjectsUsingBlock:^(TranslatePart *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        if (obj.part.length) {
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = typeTextColor;
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kHorizontalMargin);
                    if (lastView) {
                        if (idx == 0) {
                            make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                        } else {
                            make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding);
                        }
                    } else {
                        make.top.offset(kVerticalMargin);
                    }
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_parts";
        }
        
        [self layoutSubtreeIfNeeded];
        
        EDLabel *meanLabel = [EDLabel new];
        [self addSubview:meanLabel];
        NSString *text = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
        meanLabel.text = text;

        __block CGFloat leading = partTextFiled.x;

        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.greaterThanOrEqualTo(@(15));
            make.right.equalTo(self).offset(-kHorizontalMargin);

            if (partTextFiled) {
                make.top.equalTo(partTextFiled).offset(0);
                CGFloat leftLeading = 5;
                make.left.equalTo(partTextFiled.mas_right).offset(leftLeading);
                leading += partTextFiled.width + leftLeading;
            } else {
                CGFloat leftLeading = kHorizontalMargin + kFixWrappingLabelMargin;
                make.left.equalTo(self).offset(leftLeading);
                leading += leftLeading;
                if (lastView) {
                    if (idx == 0) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                    } else {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding);
                    }
                } else {
                    make.top.offset(kHorizontalMargin);
                }
            }
        }];
        meanLabel.mas_key = @"meanTextField_parts";
        
        [meanLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            CGFloat width = MainWindow.shared.width - leading;
            meanLabel.width = width;
            CGFloat height = [meanLabel getHeight];
            make.height.greaterThanOrEqualTo(@(height));
        }];

        lastView = meanLabel;
    }];
    
    [wordResult.exchanges enumerateObjectsUsingBlock:^(TranslateExchange *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString stringWithFormat:@"%@: ", obj.name];
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin);
                if (lastView) {
                    if (idx == 0) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                    } else {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding);
                        ;
                    }
                } else {
                    make.top.offset(kHorizontalMargin);
                }
            }];
        }];
        nameTextFiled.mas_key = @"nameTextFiled_exchanges";
        
        
        [obj.words enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSButton *wordButton = [NSButton mm_make:^(NSButton *_Nonnull button) {
                [self addSubview:button];
                button.bordered = NO;
                button.imageScaling = NSImageScaleProportionallyDown;
                button.bezelStyle = NSBezelStyleRegularSquare;
                [button setButtonType:NSButtonTypeMomentaryChange];
                button.attributedTitle = [NSAttributedString mm_attributedStringWithString:obj font:textFont color:[NSColor mm_colorWithHexString:@"#007AFF"]];
                [button sizeToFit];
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (idx == 0) {
                        make.left.equalTo(nameTextFiled.mas_right);
                    } else {
                        make.left.equalTo(lastView.mas_right).offset(5);
                    }
                    make.centerY.equalTo(nameTextFiled);
                }];
                
                mm_weakify(self, obj)
                [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
                    mm_strongify(self, obj) if (self.clickTextBlock) {
                        self.clickTextBlock(self, obj);
                    }
                    return RACSignal.empty;
                }]];
            }];
            wordButton.mas_key = @"wordButton_words";
            
            
            lastView = wordButton;
        }];
    }];
    
    __block NSString *lastSimpleWordPart = nil;
    
    [wordResult.simpleWords enumerateObjectsUsingBlock:^(TranslateSimpleWord *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        if (obj.part.length && (!lastSimpleWordPart || ![obj.part isEqualToString:lastSimpleWordPart])) {
            // 添加 part label
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = typeTextColor;
                textField.font = textFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kHorizontalMargin);
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                    } else {
                        make.top.offset(kHorizontalMargin);
                    }
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_simpleWords";
            
            
            lastSimpleWordPart = obj.part;
        }
        
        NSButton *wordButton = [NSButton mm_make:^(NSButton *_Nonnull button) {
            [self addSubview:button];
            button.bordered = NO;
            button.imageScaling = NSImageScaleProportionallyDown;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            button.attributedTitle = [NSAttributedString mm_attributedStringWithString:obj.word font:[NSFont systemFontOfSize:13] color:[NSColor mm_colorWithHexString:@"#007AFF"]];
            [button sizeToFit];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin);
                if (partTextFiled) {
                    make.top.equalTo(partTextFiled.mas_bottom).offset(5);
                } else {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(2);
                    } else {
                        make.top.offset(kHorizontalMargin);
                    }
                }
            }];
            mm_weakify(self, obj)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
                mm_strongify(self, obj) if (self.clickTextBlock) {
                    self.clickTextBlock(self, obj.word);
                }
                return RACSignal.empty;
            }]];
        }];
        wordButton.mas_key = @"wordButton_simpleWords";
        
        
        NSTextField *meanTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "] ?: @"";
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.backgroundColor = NSColor.clearColor;
            textField.alignment = NSTextAlignmentLeft;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(wordButton.mas_right).offset(8);
                make.top.equalTo(wordButton);
                make.right.lessThanOrEqualTo(self).offset(-kHorizontalMargin);
            }];
        }];
        meanTextField.mas_key = @"meanTextField_simpleWords";
        
        
        lastView = meanTextField;
    }];
    
    if (result.wordResult || result.normalResults.count) {
        self.audioButton = [EDButton mm_make:^(NSButton *_Nonnull button) {
            [self addSubview:button];
            button.bordered = NO;
            button.imageScaling = NSImageScaleProportionallyDown;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            button.image = [NSImage imageNamed:@"audio"];
            button.toolTip = @"播放音频";
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                make.left.offset(kHorizontalMargin);
                make.width.height.equalTo(@26);
            }];
            mm_weakify(self)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
                mm_strongify(self) if (self.audioActionBlock) {
                    self.audioActionBlock(self);
                }
                return RACSignal.empty;
            }]];
        }];
        
        self.textCopyButton = [EDButton mm_make:^(NSButton *_Nonnull button) {
            [self addSubview:button];
            button.bordered = NO;
            button.imageScaling = NSImageScaleProportionallyDown;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            button.image = [NSImage imageNamed:@"copy"];
            button.toolTip = @"复制";
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.audioButton.mas_right);
                make.bottom.equalTo(self.audioButton);
                make.width.height.equalTo(self.audioButton);
            }];
            mm_weakify(self)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
                mm_strongify(self) if (self.copyActionBlock) {
                    self.copyActionBlock(self);
                }
                return RACSignal.empty;
            }]];
        }];
        
        lastView = self.textCopyButton;
    }
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.bottom.greaterThanOrEqualTo(lastView.mas_bottom).offset(kHorizontalMargin);
        }
    }];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    CGPoint point = theEvent.locationInWindow;
    point = [self convertPoint:point fromView:nil];
    
    [self excuteLight:^(NSButton *button) {
        NSColor *highlightBgColor = [NSColor mm_colorWithHexString:@"#E2E2E2"];
        [self hightlightCopyButtonBgColor:highlightBgColor point:point];
    } drak:^(NSButton *button) {
        [self hightlightCopyButtonBgColor:DarkBorderColor point:point];
    }];
}

- (void)hightlightCopyButtonBgColor:(NSColor *)color point:(CGPoint)point {
    for (NSButton *button in self.audioButtons) {
        if (CGRectContainsPoint(button.frame, point)) {
            [[button cell] setBackgroundColor:color];
        }
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    for (NSButton *button in self.audioButtons) {
        [[button cell] setBackgroundColor:NSColor.clearColor];
        [[button cell] setBackgroundColor:NSColor.clearColor];
    }
}

@end
