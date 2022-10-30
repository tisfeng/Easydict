//
//  WordResultView.m
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "WordResultView.h"
#import "ImageButton.h"

#define kMargin 12.0
/// wrappingLabel的约束需要偏移2,不知道是什么神设计
#define kFixWrappingLabelMargin 2.0

@interface WordResultView ()

@end

@implementation WordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        [self.layer excuteLight:^(id  _Nonnull x) {
            [x setBackgroundColor:[NSColor mm_colorWithHexString:@"#EEEEEE"].CGColor];
        } drak:^(id  _Nonnull x) {
            [x setBackgroundColor:DarkGrayColor.CGColor];
        }];
    }
    return self;
}

- (void)refreshWithResult:(TranslateResult *)result {
    self.result = result;
    TranslateWordResult *wordResult = result.wordResult;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    __block NSView *lastView = nil;
    
    [wordResult.phonetics enumerateObjectsUsingBlock:^(TranslatePhonetic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = obj.name;
            [textField excuteLight:^(id  _Nonnull x) {
                [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
            } drak:^(id  _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            textField.font = [NSFont systemFontOfSize:13];
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kMargin);
                if (idx == 0) {
                    make.top.offset(kMargin);
                }else {
                    make.top.equalTo(lastView.mas_bottom);
                }
            }];
        }];
        
        // 部分没有音标文本
        NSTextField *valueTextField = nil;
        if (obj.value.length) {
            valueTextField = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = [NSString stringWithFormat:@"[%@]", obj.value];
                [textField excuteLight:^(id  _Nonnull x) {
                    [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
                } drak:^(id  _Nonnull x) {
                    [x setTextColor:NSColor.whiteColor];
                }];
                textField.font = [NSFont systemFontOfSize:13];
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(nameTextFiled.mas_right).offset(8);
                    make.centerY.equalTo(nameTextFiled);
                }];
            }];
        }
        
        NSButton *audioButton = [ImageButton mm_make:^(ImageButton * _Nonnull button) {
            [self addSubview:button];
            button.bordered = NO;
            button.imageScaling = NSImageScaleProportionallyDown;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            button.image = [NSImage imageNamed:@"audio"];
            button.toolTip = @"播放音频";
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(valueTextField ? valueTextField.mas_right : nameTextFiled.mas_right).offset(6);
                make.centerY.equalTo(valueTextField ?: nameTextFiled);
                make.width.height.equalTo(@26);
            }];
            mm_weakify(self, obj)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
                mm_strongify(self, obj)
                if (self.playAudioBlock) {
                    self.playAudioBlock(self, obj.speakURL);
                }
                return RACSignal.empty;
            }]];
        }];
        
        lastView = audioButton;
    }];
    
    [wordResult.parts enumerateObjectsUsingBlock:^(TranslatePart * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSTextField *partTextFiled = nil;
        if (obj.part.length) {
            partTextFiled = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = [NSColor mm_colorWithHexString:@"#999999"];
                textField.font = [NSFont systemFontOfSize:13];
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kMargin);
                    if (lastView) {
                        if (idx == 0) {
                            make.top.equalTo(lastView.mas_bottom).offset(10);
                        }else {
                            make.top.equalTo(lastView.mas_bottom);
                        }
                    }else {
                        make.top.offset(kMargin);
                    }
                }];
            }];
        }
        
        NSTextField *meanTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField * _Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
            [textField excuteLight:^(id  _Nonnull x) {
                [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
            } drak:^(id  _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            textField.font = [NSFont systemFontOfSize:13];
            textField.backgroundColor = NSColor.clearColor;
            textField.alignment = NSTextAlignmentLeft;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                if (partTextFiled) {
                    make.left.equalTo(partTextFiled.mas_right).offset(8);
                    make.top.equalTo(partTextFiled);
                }else {
                    make.left.offset(kMargin + kFixWrappingLabelMargin);
                    if (lastView) {
                        if (idx == 0) {
                            make.top.equalTo(lastView.mas_bottom).offset(10);
                        }else {
                            make.top.equalTo(lastView.mas_bottom);
                        }
                    }else {
                        make.top.offset(kMargin);
                    }
                }
                make.right.lessThanOrEqualTo(self).offset(-kMargin);
            }];
        }];
        
        lastView = meanTextField;
    }];
    
    [wordResult.exchanges enumerateObjectsUsingBlock:^(TranslateExchange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString stringWithFormat:@"%@: ", obj.name];
            [textField excuteLight:^(id  _Nonnull x) {
                [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
            } drak:^(id  _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            textField.font = [NSFont systemFontOfSize:13];
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kMargin);
                if (lastView) {
                    if (idx == 0) {
                        make.top.equalTo(lastView.mas_bottom).offset(10);
                    }else {
                        make.top.equalTo(lastView.mas_bottom);
                    }
                }else {
                    make.top.offset(kMargin);
                }
            }];
        }];
        
        [obj.words enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSButton *wordButton = [NSButton mm_make:^(NSButton * _Nonnull button) {
                [self addSubview:button];
                button.bordered = NO;
                button.imageScaling = NSImageScaleProportionallyDown;
                button.bezelStyle = NSBezelStyleRegularSquare;
                [button setButtonType:NSButtonTypeMomentaryChange];
                button.attributedTitle = [NSAttributedString mm_attributedStringWithString:obj font:[NSFont systemFontOfSize:13] color:[NSColor mm_colorWithHexString:@"#007AFF"]];
                [button sizeToFit];
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (idx == 0) {
                        make.left.equalTo(nameTextFiled.mas_right);
                    }else {
                        make.left.equalTo(lastView.mas_right).offset(5);
                    }
                    make.centerY.equalTo(nameTextFiled);
                }];
                mm_weakify(self, obj)
                [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
                    mm_strongify(self, obj)
                    if (self.selectWordBlock) {
                        self.selectWordBlock(self, obj);
                    }
                    return RACSignal.empty;
                }]];
            }];
            
            lastView = wordButton;
        }];
    }];
    
    __block NSString *lastSimpleWordPart = nil;
    
    [wordResult.simpleWords enumerateObjectsUsingBlock:^(TranslateSimpleWord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSTextField *partTextFiled = nil;
        if (obj.part.length && (!lastSimpleWordPart || ![obj.part isEqualToString:lastSimpleWordPart])) {
            // 添加 part label
            partTextFiled = [NSTextField mm_make:^(NSTextField * _Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = [NSColor mm_colorWithHexString:@"#999999"];
                textField.font = [NSFont systemFontOfSize:13];
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kMargin);
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(10);
                    }else {
                        make.top.offset(kMargin);
                    }
                }];
            }];
            
            lastSimpleWordPart = obj.part;
        }
        
        NSButton *wordButton = [NSButton mm_make:^(NSButton * _Nonnull button) {
            [self addSubview:button];
            button.bordered = NO;
            button.imageScaling = NSImageScaleProportionallyDown;
            button.bezelStyle = NSBezelStyleRegularSquare;
            [button setButtonType:NSButtonTypeMomentaryChange];
            button.attributedTitle = [NSAttributedString mm_attributedStringWithString:obj.word font:[NSFont systemFontOfSize:13] color:[NSColor mm_colorWithHexString:@"#007AFF"]];
            [button sizeToFit];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kMargin);
                if (partTextFiled) {
                    make.top.equalTo(partTextFiled.mas_bottom).offset(5);
                }else {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(2);
                    }else {
                        make.top.offset(kMargin);
                    }
                }
            }];
            mm_weakify(self, obj)
            [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
                mm_strongify(self, obj)
                if (self.selectWordBlock) {
                    self.selectWordBlock(self, obj.word);
                }
                return RACSignal.empty;
            }]];
        }];
        
        NSTextField *meanTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField * _Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "] ?: @"";
            [textField excuteLight:^(id  _Nonnull x) {
                [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
            } drak:^(id  _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            textField.font = [NSFont systemFontOfSize:13];
            textField.backgroundColor = NSColor.clearColor;
            textField.alignment = NSTextAlignmentLeft;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(wordButton.mas_right).offset(8);
                make.top.equalTo(wordButton);
                make.right.lessThanOrEqualTo(self).offset(-kMargin);
            }];
        }];
        
        lastView = meanTextField;
    }];
    
    if (result.normalResults.count) {
        NSTextField *meanTextField = [[NSTextField wrappingLabelWithString:@""] mm_put:^(NSTextField * _Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString mm_stringByCombineComponents:result.normalResults separatedString:@"\n"] ?: @"";
            [textField excuteLight:^(id  _Nonnull x) {
                [x setTextColor:[NSColor mm_colorWithHexString:@"#333333"]];
            } drak:^(id  _Nonnull x) {
                [x setTextColor:NSColor.whiteColor];
            }];
            textField.font = [NSFont systemFontOfSize:13];
            textField.backgroundColor = NSColor.clearColor;
            textField.alignment = NSTextAlignmentLeft;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(10);
                }else {
                    make.top.offset(kMargin);
                }
                make.left.offset(kMargin + kFixWrappingLabelMargin);
                make.right.lessThanOrEqualTo(self).offset(-kMargin);
            }];
        }];
        
        lastView = meanTextField;
    }
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.greaterThanOrEqualTo(lastView.mas_bottom).offset(kMargin);
    }];
}

@end
