//
//  EZCommonResultView.m
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZWordResultView.h"
#import "ImageButton.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"
#import "EZLabel.h"
#import "TextView.h"
#import "NSTextView+Height.h"
#import "EZMainWindow.h"
#import "EZConst.h"

static const CGFloat kHorizontalMargin = 10;
static const CGFloat kVerticalMargin = 12;
static const CGFloat kVerticalPadding = 8;

/// wrappingLabel的约束需要偏移2,不知道是什么神设计
static const CGFloat kFixWrappingLabelMargin = 2;

@interface EZWordResultView ()

@property (nonatomic, strong) MASConstraint *textViewHeightConstraint;

@end


@implementation EZWordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        [self.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
        } drak:^(CALayer *layer) {
            layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
        }];
    }
    return self;
}

- (void)refreshWithResult:(TranslateResult *)result {
    self.result = result;
    TranslateWordResult *wordResult = result.wordResult;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    __block NSView *lastView = nil;
    NSFont *textFont = [NSFont systemFontOfSize:14];
    NSFont *typeTextFont = textFont;
    NSColor *typeTextColor = [NSColor mm_colorWithHexString:@"#999999"];
    
    if (result.normalResults.count) {
        NSTextField *typeTextField;
        if (result.wordResult) {
            typeTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = @"释义：";
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.textColor = typeTextColor;
                textField.backgroundColor = NSColor.clearColor;
                
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                    } else {
                        make.top.offset(kVerticalMargin);
                    }
                    make.left.mas_equalTo(kHorizontalMargin);
                }];
            }];
            typeTextField.mas_key = @"typeTextField_normalResults";
            [self layoutSubtreeIfNeeded];
        }
                
        NSString *text = [NSString mm_stringByCombineComponents:result.normalResults separatedString:@"\n"] ?: @"";
        
        EZLabel *resultLabel = [EZLabel new];
        [self addSubview:resultLabel];
        resultLabel.text = text;

        __block CGFloat leftMargin = CGRectGetMaxX(typeTextField.frame);
        
        [resultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin);
            if (typeTextField) {
                make.top.equalTo(typeTextField);
                CGFloat leftLeading = 0;
                make.left.equalTo(typeTextField.mas_right).offset(leftLeading);
                leftMargin += leftLeading;
            } else {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                } else {
                    make.top.equalTo(self).offset(kVerticalMargin);
                }
                make.left.equalTo(self).offset(kHorizontalMargin);
            }
        }];
        resultLabel.mas_key = @"resultLabel_normalResults";
        lastView = resultLabel;

        [self updateLabelHeight:resultLabel leftMargin:leftMargin];
    }
    
    [wordResult.phonetics enumerateObjectsUsingBlock:^(TranslatePhonetic *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = obj.name;
            textField.textColor = typeTextColor;
            textField.font = textFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin);
                if (idx == 0) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                    } else {
                        make.top.offset(kHorizontalMargin);
                    }
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
                textField.stringValue = [NSString stringWithFormat:@"/%@/", obj.value];
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
                    make.left.equalTo(nameTextFiled.mas_right).offset(5);
                    make.centerY.equalTo(nameTextFiled);
                }];
            }];
            valueTextField.mas_key = @"valueTextField_phonetics";
        }
        
        EZHoverButton *audioButton = [[EZHoverButton alloc] init];
        [self addSubview:audioButton];
        audioButton.image = [NSImage imageNamed:@"audio"];
        audioButton.toolTip = @"播放音频";
        [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
            NSView *leftView = valueTextField ?: nameTextFiled;
            make.left.equalTo(leftView.mas_right).offset(4);
            make.centerY.equalTo(valueTextField ?: nameTextFiled);
            make.width.height.mas_equalTo(23);
        }];
        
        mm_weakify(self);
        [audioButton setClickBlock:^(EZButton *_Nonnull button) {
            NSLog(@"click audioButton");
            
            mm_strongify(self);
            if (self.playAudioBlock) {
                self.playAudioBlock(self, result.text);
            }
            
        }];
       
        audioButton.mas_key = @"audioButton_phonetics";
        
        lastView = audioButton;
    }];


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
        
        EZLabel *meanLabel = [EZLabel new];
        [self addSubview:meanLabel];
        NSString *text = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
        meanLabel.text = text;

        __block CGFloat leftMargin = CGRectGetMaxX(partTextFiled.frame);

        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin);

            if (partTextFiled) {
                make.top.equalTo(partTextFiled);
                CGFloat leftLeading = 5;
                make.left.equalTo(partTextFiled.mas_right).offset(leftLeading);
                leftMargin += leftLeading;
            } else {
                CGFloat leftLeading = kHorizontalMargin + kFixWrappingLabelMargin;
                make.left.equalTo(self).offset(leftLeading);
                leftMargin += leftLeading;
                if (lastView) {
                    CGFloat topPadding = kVerticalPadding;
                    if (idx == 0) {
                        topPadding = kVerticalMargin;
                    }
                    make.top.equalTo(lastView.mas_bottom).offset(topPadding);
                } else {
                    make.top.offset(kHorizontalMargin);
                }
            }
        }];
        meanLabel.mas_key = @"meanTextField_parts";
        lastView = meanLabel;
        
        [self updateLabelHeight:meanLabel leftMargin:leftMargin];
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
                    mm_strongify(self, obj);
                    
                    if (self.copyTextBlock) {
                        self.copyTextBlock(self, obj);
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
                mm_strongify(self, obj) if (self.copyTextBlock) {
                    self.copyTextBlock(self, obj.word);
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
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.bottom.greaterThanOrEqualTo(lastView.mas_bottom).offset(5);
        }
    }];
}

- (void)updateLabelHeight:(EZLabel *)label leftMargin:(CGFloat)leftMargin {
    CGFloat rightMargin = kHorizontalMargin;
    CGFloat width = EZMainWindow.shared.width - leftMargin - rightMargin - 2 * kMainHorizontalMargin;
//    NSLog(@"text: %@, width: %@", label.text, @(width));

    // ⚠️ 很奇怪，比如实际计算结果为 364，但界面渲染却是 364.5 😑
    label.width = width;
    CGFloat height = [label getHeight];
    [label mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(height));
        make.width.mas_greaterThanOrEqualTo(label.width);
    }];
    
//    NSLog(@"height: %@", @(height));
}

@end
