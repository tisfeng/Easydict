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
#import "RoundRectButton.h"

static const CGFloat kHorizontalMargin = 10;
static const CGFloat kVerticalMargin = 12;
static const CGFloat kVerticalPadding = 5;

/// wrappingLabel的约束需要偏移2,不知道是什么神设计
static const CGFloat kFixWrappingLabelMargin = 2;

@interface WordResultView ()

@property (nonatomic, strong) NSMutableArray<NSButton *> *audioButtons;

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

        RoundRectButton *audioButton = [[RoundRectButton alloc] init];
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
              .equalTo(valueTextField ? valueTextField.mas_right
                                      : nameTextFiled.mas_right)
              .offset(6);
          make.centerY.equalTo(valueTextField ?: nameTextFiled);
          make.width.height.mas_equalTo(23);
        }];
                    
        [audioButton setActionBlock:^(RoundRectButton * _Nonnull button) {
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

    [wordResult.parts enumerateObjectsUsingBlock:^(TranslatePart *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        if (obj.part.length) {
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = [NSColor mm_colorWithHexString:@"#999999"];
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
                        }
                    } else {
                        make.top.offset(kVerticalMargin);
                    }
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_parts";
        }

        NSTextField *meanTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.backgroundColor = NSColor.clearColor;
            textField.alignment = NSTextAlignmentLeft;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                if (partTextFiled) {
                    make.left.equalTo(partTextFiled.mas_right).offset(8);
                    make.top.equalTo(partTextFiled);
                } else {
                    make.left.offset(kHorizontalMargin + kFixWrappingLabelMargin);
                    if (lastView) {
                        if (idx == 0) {
                            make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin);
                        } else {
                            make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding);;
                        }
                    } else {
                        make.top.offset(kHorizontalMargin);
                    }
                }
                make.right.lessThanOrEqualTo(self).offset(-kHorizontalMargin);
            }];
        }];
        meanTextField.mas_key = @"meanTextField_parts";


        lastView = meanTextField;
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
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding);;
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
                                mm_strongify(self, obj) if (self.selectWordBlock) {
                                    self.selectWordBlock(self, obj);
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
                textField.textColor = [NSColor mm_colorWithHexString:@"#999999"];
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
                            mm_strongify(self, obj) if (self.selectWordBlock) {
                                self.selectWordBlock(self, obj.word);
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

    if (result.normalResults.count) {
        NSTextField *meanTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString mm_stringByCombineComponents:result.normalResults separatedString:@"\n"] ?: @"";
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.backgroundColor = NSColor.clearColor;
            textField.alignment = NSTextAlignmentLeft;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(10);
                } else {
                    make.top.offset(kHorizontalMargin);
                }
                make.left.offset(kHorizontalMargin + kFixWrappingLabelMargin);
                make.right.lessThanOrEqualTo(self).offset(-kHorizontalMargin);
            }];
        }];
        meanTextField.mas_key = @"meanTextField_normalResults";


        lastView = meanTextField;
    }

    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.greaterThanOrEqualTo(lastView.mas_bottom).offset(kHorizontalMargin);
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
