//
//  EZWordResultView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZWordResultView.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"
#import "EZLabel.h"
#import "NSTextView+Height.h"
#import "EZConst.h"
#import "EZFixedQueryWindow.h"
#import "NSString+MM.h"
#import "EZLayoutManager.h"
#import "EZWindowManager.h"
#import "EZLinkButton.h"
#import "NSImage+EZResize.h"
#import "EZQueryService.h"
#import "EZBlueTextButton.h"
#import "EZMyLabel.h"

static const CGFloat kHorizontalMargin_8 = 8;
static const CGFloat kVerticalMargin_12 = 12;
static const CGFloat kVerticalPadding_8 = 8;

@interface EZWordResultView () <NSTextViewDelegate>

@property (nonatomic, strong) EZQueryResult *result;

@end


@implementation EZWordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = EZCornerRadius_8;
        [self.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
        } drak:^(CALayer *layer) {
            layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
        }];
    }
    return self;
}

- (void)refreshWithResult:(EZQueryResult *)result {
    self.result = result;
    EZTranslateWordResult *wordResult = result.wordResult;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    __block CGFloat height = 0;
    __block NSView *lastView = nil;
    NSFont *textFont = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    NSFont *typeTextFont = textFont;
    NSColor *typeTextColor = [NSColor mm_colorWithHexString:@"#7A7A7A"];
    
    NSString *errorMsg = result.error.localizedDescription;
    
    __block CGFloat ezLabelTopOffset = 0;
    
    mm_weakify(self);
    
    BOOL showBigWord = result.wordResult && result.queryText.length && result.queryText.length < EZEnglishWordMaxLength;
    if (showBigWord) {
        NSTextField *wordTextField = nil;
        wordTextField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = result.queryText;
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = [NSFont systemFontOfSize:24 weight:NSFontWeightSemibold];
            textField.selectable = YES;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                [textField sizeToFit];
                
                CGFloat topOffset = 10;
                height += (topOffset + textField.height);
                // NSLog(@"height = %1.f", height);
                
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                } else {
                    make.top.offset(topOffset);
                }
                make.left.mas_equalTo(kHorizontalMargin_8 + 1);
                make.height.mas_equalTo(textField.height);
            }];
        }];
        wordTextField.mas_key = @"wordTextField";
        lastView = wordTextField;
    }
    
    if (result.normalResults.count || errorMsg.length > 0) {
        NSTextField *typeTextField;
        __block CGFloat exceptedWidth = 0;
        
        if (result.wordResult && result.normalResults.count) {
            typeTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = NSLocalizedString(@"explain", nil);
                textField.maximumNumberOfLines = 1;
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.textColor = typeTextColor;
                textField.backgroundColor = NSColor.clearColor;
                [textField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
                
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                    } else {
                        make.top.offset(kVerticalMargin_12);
                    }
                    make.left.mas_equalTo(kHorizontalMargin_8);
                    exceptedWidth += kHorizontalMargin_8;
                }];
                
                [textField sizeToFit];
            }];
            typeTextField.mas_key = @"typeTextField_explain";
        }
        
        exceptedWidth += ceil(typeTextField.width);
        
        NSString *text = nil;
        if (result.translatedText.length > 0) {
            text = result.translatedText;
        } else if (!result.wordResult && errorMsg.length) {
            text = errorMsg;
        } else if (!result.hasTranslatedResult) {
            text = @"No Result.";
        }
        
        if (text.length) {
            EZLabel *resultLabel = [[EZLabel alloc] init];
            [self addSubview:resultLabel];
            resultLabel.text = text;
            resultLabel.delegate = self;
            
            [resultLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self).offset(-kHorizontalMargin_8);
                exceptedWidth += kHorizontalMargin_8;
                
                CGSize labelSize = [self labelSize:resultLabel exceptedWidth:exceptedWidth];
                make.size.mas_equalTo(labelSize).priorityHigh();
                
                // This means the label text has more than 2 lines, so we need to adjust the top offset.
                if (labelSize.height > typeTextField.height * 2) {
                    ezLabelTopOffset = -1;
                }
                
                height += (kVerticalMargin_12 + labelSize.height);
                // NSLog(@"height = %1.f", height);
                
                if (typeTextField) {
                    make.top.equalTo(typeTextField).offset(ezLabelTopOffset);
                    make.left.equalTo(typeTextField.mas_right);
                } else {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                    } else {
                        make.top.equalTo(self).offset(kVerticalMargin_12);
                    }
                    
                    CGFloat leftPadding = 5;
                    exceptedWidth += leftPadding;
                    make.left.equalTo(self).offset(leftPadding);
                }
            }];
            resultLabel.mas_key = @"resultLabel_normalResults";
            lastView = resultLabel;
        }
        
        if (result.promptTitle.length && result.promptURL.length) {
            NSTextField *promptTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = NSLocalizedString(@"please_look", nil);
                textField.font = [NSFont systemFontOfSize:14];
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
                
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    CGFloat topOffset = 20;
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                    } else {
                        make.top.offset(topOffset);
                    }
                    height += topOffset;
                    
                    make.left.mas_equalTo(kHorizontalMargin_8);
                }];
                [textField sizeToFit];
            }];
            promptTextField.mas_key = @"promptTextField";
            
            EZBlueTextButton *promptButton = [[EZBlueTextButton alloc] init];
            [self addSubview:promptButton];
            [promptButton setTitle:result.promptTitle];
            promptButton.openURL = result.promptURL;
            
            [promptButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(promptTextField.mas_right).offset(0);
                make.centerY.equalTo(promptTextField);
            }];
            
            height += promptButton.height;
            
            promptButton.mas_key = @"promptButton";
            lastView = promptButton;
        }
    }
    
    [wordResult.phonetics enumerateObjectsUsingBlock:^(EZTranslatePhonetic *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = obj.name;
            textField.textColor = typeTextColor;
            textField.font = textFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                [textField sizeToFit];
                height += textField.height;
                
                make.left.offset(kHorizontalMargin_8);
                make.height.mas_equalTo(textField.height);
                if (idx == 0) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                        height += kVerticalMargin_12;
                    } else {
                        make.top.offset(kHorizontalMargin_8);
                        height += kVerticalPadding_8;
                    }
                } else {
                    CGFloat topOffset = kVerticalPadding_8;
                    make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                    height += topOffset;
                }
            }];
            //            NSLog(@"height = %1.f", height);
        }];
        nameTextFiled.mas_key = @"nameTextFiled_phonetics";
        lastView = nameTextFiled;
        
        // 部分没有音标文本
        NSTextField *valueTextField = nil;
        if (obj.value.length) {
            valueTextField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = [NSString stringWithFormat:@"/ %@ /", obj.value];
                [textField excuteLight:^(id _Nonnull x) {
                    [x setTextColor:NSColor.resultTextLightColor];
                } drak:^(id _Nonnull x) {
                    [x setTextColor:NSColor.resultTextDarkColor];
                }];
                textField.font = textFont;
                textField.selectable = YES;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(nameTextFiled.mas_right).offset(kHorizontalMargin_8);
                    make.centerY.equalTo(nameTextFiled);
                }];
            }];
            valueTextField.mas_key = @"valueTextField_phonetics";
        }
        
        EZHoverButton *audioButton = [[EZHoverButton alloc] init];
        [self addSubview:audioButton];
        audioButton.image = [NSImage imageNamed:@"audio"];
        audioButton.toolTip = @"Play";
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
                self.playAudioBlock(result.queryText, obj.speakURL);
            }
        }];
        audioButton.mas_key = @"audioButton_phonetics";
    }];
    
    NSTextField *tagLabel = nil;
    __block NSScrollView *tagScrollView = nil;
    if (wordResult.tags.count) {
        tagLabel = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = NSLocalizedString(@"tag", nil);
            textField.textColor = typeTextColor;
            textField.font = typeTextFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
            
            [textField sizeToFit];
            
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(textField.height);
                make.left.offset(kHorizontalMargin_8);
                
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                } else {
                    make.top.offset(kVerticalMargin_12);
                }
                height += (textField.height + kVerticalMargin_12);
            }];
        }];
        tagLabel.mas_key = @"tagLabel";
        lastView = tagLabel;
        
        __block NSView *tagContentView = nil;
        __block CGFloat tagContentViewWidth = 0;
        CGFloat padding = 6;
        
        __block NSButton *lastTagButton = nil;
        [wordResult.tags enumerateObjectsUsingBlock:^(NSString *_Nonnull tag, NSUInteger idx, BOOL *_Nonnull stop) {
            if (tag.length == 0) {
                return;
            }
            
            NSButton *tagButton = [[NSButton alloc] init];
            tagButton.title = tag;
            [tagButton excuteLight:^(NSButton *tagButton) {
                NSColor *tagColor = [NSColor mm_colorWithHexString:@"#878785"];
                [self updateTagButton:tagButton tagColor:tagColor];
            } drak:^(NSButton *tagButton) {
                NSColor *tagColor = [NSColor mm_colorWithHexString:@"#BDBDB9"];
                [self updateTagButton:tagButton tagColor:tagColor];
            }];
            
            [tagButton sizeToFit];
            CGSize size = tagButton.size;
            CGFloat expandValue = 3;
            CGSize newSize = CGSizeMake(size.width + expandValue * 2, size.height + expandValue);
            
            if (!tagScrollView) {
                tagScrollView = [[NSScrollView alloc] init];
                [self addSubview:tagScrollView];
                [tagScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(tagLabel.mas_right).offset(padding + 2);
                    make.height.mas_equalTo(newSize.height);
                    make.centerY.equalTo(tagLabel);
                }];
                
                tagContentView = [[NSView alloc] init];
                [tagScrollView addSubview:tagContentView];
                tagContentView.wantsLayer = YES;
                [tagContentView.layer excuteLight:^(CALayer *layer) {
                    layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
                } drak:^(CALayer *layer) {
                    layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
                }];
                
                tagContentView.height = newSize.height;
                tagScrollView.documentView = tagContentView;
                tagScrollView.horizontalScrollElasticity = NSScrollElasticityNone;
                tagScrollView.verticalScrollElasticity = NSScrollElasticityNone;
                tagScrollView.hasHorizontalScroller = NO;
            }
            [tagContentView addSubview:tagButton];
            
            [tagButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(newSize);
                make.centerY.equalTo(tagLabel);
                if (lastTagButton) {
                    make.left.equalTo(lastTagButton.mas_right).offset(padding);
                } else {
                    make.left.equalTo(tagContentView);
                }
            }];
            lastTagButton = tagButton;
            tagContentViewWidth += (newSize.width + padding);
        }];
        
        tagContentView.width = tagContentViewWidth;
        
        CGFloat maxTagScrollViewWidth = self.width - (kHorizontalMargin_8 + tagLabel.width + padding * 2);
        CGFloat tagScrollViewWidth = MIN(tagContentViewWidth, maxTagScrollViewWidth);
        [tagScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(tagScrollViewWidth);
        }];
    }
    
    
    [wordResult.parts enumerateObjectsUsingBlock:^(EZTranslatePart *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        __block CGFloat exceptedWidth = 0;
        
        if (obj.part.length) {
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = typeTextColor;
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
                
                [textField sizeToFit];
                
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.height.mas_equalTo(textField.height);
                    make.left.offset(kHorizontalMargin_8);
                    exceptedWidth += kHorizontalMargin_8;
                    
                    if (lastView) {
                        CGFloat topOffset = kVerticalPadding_8;
                        if (idx == 0) {
                            topOffset = kVerticalMargin_12;
                        }
                        make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                        height += topOffset;
                    } else {
                        make.top.offset(kVerticalMargin_12);
                        height += kVerticalMargin_12;
                    }
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_parts";
        }
        
        EZLabel *meanLabel = [[EZLabel alloc] init];
        [self addSubview:meanLabel];
        NSString *text = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
        meanLabel.text = text;
        meanLabel.delegate = self;
        
        exceptedWidth += ceil(partTextFiled.width);
        
        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
            
            if (partTextFiled) {
                make.top.equalTo(partTextFiled);
                CGFloat leftLeading = 2;
                make.left.equalTo(partTextFiled.mas_right).offset(leftLeading);
                exceptedWidth += leftLeading;
            } else {
                make.left.equalTo(self).offset(kHorizontalMargin_8);
                exceptedWidth += kHorizontalMargin_8;
                
                if (lastView) {
                    CGFloat topPadding = kVerticalPadding_8;
                    if (idx == 0) {
                        topPadding = kVerticalMargin_12;
                    }
                    make.top.equalTo(lastView.mas_bottom).offset(topPadding);
                    height += topPadding;
                    
                } else {
                    make.top.offset(kHorizontalMargin_8);
                    height += kVerticalPadding_8;
                }
            }
            CGSize labelSize = [self labelSize:meanLabel exceptedWidth:exceptedWidth];
            if (labelSize.height < partTextFiled.height) {
                labelSize.height = partTextFiled.height;
            }
            
            make.size.mas_equalTo(labelSize).priorityHigh();
            
            height += labelSize.height;
            //            NSLog(@"height = %1.f", height);
        }];
        meanLabel.mas_key = @"meanTextField_parts";
        lastView = meanLabel;
    }];
    
    [wordResult.exchanges enumerateObjectsUsingBlock:^(EZTranslateExchange *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = [NSString stringWithFormat:@"%@:", obj.name];
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.selectable = YES;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            
            [textField sizeToFit];
            height += textField.height;
            
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin_8);
                make.height.mas_equalTo(textField.height);
                
                if (lastView) {
                    CGFloat topPadding = kVerticalPadding_8;
                    if (idx == 0) {
                        topPadding = kVerticalMargin_12;
                    }
                    make.top.equalTo(lastView.mas_bottom).offset(topPadding);
                    height += topPadding;
                } else {
                    make.top.offset(kVerticalPadding_8);
                    height += kVerticalPadding_8;
                }
            }];
            //            NSLog(@"height = %1.f", height);
        }];
        nameTextFiled.mas_key = @"nameTextFiled_exchanges";
        lastView = nameTextFiled;
        
        __block EZBlueTextButton *lastWordButton = nil;
        [obj.words enumerateObjectsUsingBlock:^(NSString *_Nonnull word, NSUInteger idx, BOOL *_Nonnull stop) {
            EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
            [self addSubview:wordButton];
            [wordButton setTitle:word];
            
            [wordButton mas_makeConstraints:^(MASConstraintMaker *make) {
                if (!lastWordButton) {
                    make.left.equalTo(nameTextFiled.mas_right);
                } else {
                    make.left.equalTo(lastWordButton.mas_right).offset(3);
                }
                make.centerY.equalTo(nameTextFiled);
            }];
            mm_weakify(self);
            [wordButton setClickBlock:^(EZButton *_Nonnull button) {
                mm_strongify(self);
                if (self.clickTextBlock) {
                    self.clickTextBlock(word);
                    self.copyTextBlock(word);
                }
            }];
            wordButton.mas_key = @"wordButton_words";
            lastWordButton = wordButton;
        }];
    }];
    
    __block NSString *lastSimpleWordPart = nil;
    
    [wordResult.simpleWords enumerateObjectsUsingBlock:^(EZTranslateSimpleWord *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        if (!obj.showPartMeans && obj.part.length && (!lastSimpleWordPart || ![obj.part isEqualToString:lastSimpleWordPart])) {
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = typeTextColor;
                textField.font = textFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                
                [textField sizeToFit];
                height += textField.height;
                
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kHorizontalMargin_8);
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                    } else {
                        make.top.offset(kVerticalPadding_8);
                    }
                    height += kVerticalPadding_8;
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_simpleWords";
            
            lastSimpleWordPart = obj.part;
        }
        
        __block CGFloat exceptedWidth = 0;
        
        EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
        wordButton.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:wordButton];
        
        CGFloat maxButtonWidth = self.width / 2;
        NSString *title = [self multipleLineText:obj.word font:[NSFont systemFontOfSize:14] lineWidth:maxButtonWidth];
        [wordButton setTitle:title];
        
        CGSize buttonSize = wordButton.size;
        if (buttonSize.width > maxButtonWidth) {
            buttonSize.width = maxButtonWidth;
        }
        CGFloat buttonHeight = [wordButton.title mm_heightWithFont:[NSFont systemFontOfSize:14] constrainedToWidth:maxButtonWidth];
        
        
        buttonSize.height = buttonHeight + wordButton.expandValue;
        
        [wordButton mas_updateConstraints:^(MASConstraintMaker *make) {
            CGFloat leftOffset = kHorizontalMargin_8 - 2;
            exceptedWidth += leftOffset;
            make.left.offset(leftOffset); // Since button has been expanded, so need to be shifted to the left.
            if (partTextFiled) {
                CGFloat topOffset = 3;
                height += topOffset;
                make.top.equalTo(partTextFiled.mas_bottom).offset(topOffset);
            } else {
                CGFloat topOffset = kHorizontalMargin_8;
                if (lastView) {
                    topOffset = 5;
                    if (idx == 0) {
                        topOffset = 8;
                    }
                    make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                } else {
                    make.top.offset(topOffset);
                }
                height += topOffset;
            }
            make.size.mas_equalTo(buttonSize);
        }];
        
        exceptedWidth += buttonSize.width;
        
        mm_weakify(self);
        [wordButton setClickBlock:^(EZButton *_Nonnull button) {
            mm_strongify(self);
            if (self.clickTextBlock) {
                self.clickTextBlock(obj.word);
                self.copyTextBlock(obj.word);
            }
        }];
        wordButton.mas_key = @"wordButton_simpleWords";
        
        
        EZLabel *meanLabel = [[EZLabel alloc] init];
        meanLabel.text = obj.meansText;
        
        [self addSubview:meanLabel];
        [meanLabel excuteLight:^(id _Nonnull x) {
            [x setTextColor:NSColor.resultTextLightColor];
        } drak:^(id _Nonnull x) {
            [x setTextColor:NSColor.resultTextDarkColor];
        }];
        
        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            CGFloat topOffset = wordButton.expandValue / 2; // expandValue = 6;
            make.top.equalTo(wordButton).offset(topOffset); // Since word button has expand vlaue
            
            CGFloat leftOffset = 4;
            make.left.equalTo(wordButton.mas_right).offset(leftOffset);
            exceptedWidth += leftOffset;
            
            make.right.lessThanOrEqualTo(self).offset(-5);
            exceptedWidth += 5;
            
            CGSize labelSize = [self labelSize:meanLabel exceptedWidth:exceptedWidth];
            
            CGFloat labelHeight = buttonSize.height - topOffset;
            if (labelSize.height + topOffset > labelHeight) {
                labelHeight = labelSize.height;
            }
            
            labelSize.height = labelHeight;
            make.size.mas_equalTo(labelSize).priorityHigh();
            
            height += labelHeight + topOffset;
            //            NSLog(@"height = %1.f", height);
        }];
        
        
        meanLabel.mas_key = @"meanLabel_simpleWords";
        lastView = meanLabel;
    }];
    
    if (wordResult.etymology.length) {
        __block CGFloat exceptedWidth = 0;
        
        NSTextField *typeTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
            [self addSubview:textField];
            textField.stringValue = NSLocalizedString(@"etymology", nil);
            textField.maximumNumberOfLines = 1;
            textField.font = typeTextFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.textColor = typeTextColor;
            textField.backgroundColor = NSColor.clearColor;
            [textField setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
            
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                } else {
                    make.top.offset(kVerticalMargin_12);
                }
                make.left.mas_equalTo(kHorizontalMargin_8);
                exceptedWidth += kHorizontalMargin_8;
            }];
            
            [textField sizeToFit];
        }];
        typeTextField.mas_key = @"typeTextField_etymology";
        
        exceptedWidth += ceil(typeTextField.width);
        
        EZLabel *resultLabel = [[EZLabel alloc] init];
        [self addSubview:resultLabel];
        resultLabel.text = wordResult.etymology;
        resultLabel.delegate = self;
        
        [resultLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
            
            if (typeTextField) {
                make.top.equalTo(typeTextField);
                make.left.equalTo(typeTextField.mas_right);
            } else {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                } else {
                    make.top.equalTo(self).offset(kVerticalMargin_12);
                }
                
                CGFloat leftPadding = 5;
                exceptedWidth += leftPadding;
                make.left.equalTo(self).offset(leftPadding);
            }
            
            CGSize labelSize = [self labelSize:resultLabel exceptedWidth:exceptedWidth];
            make.size.mas_equalTo(labelSize).priorityHigh();
            
            height += (kVerticalMargin_12 + labelSize.height);
            //            NSLog(@"height = %1.f", height);
        }];
        resultLabel.mas_key = @"resultLabel_etymology";
        lastView = resultLabel;
    }
    
    EZHoverButton *audioButton = [[EZHoverButton alloc] init];
    [self addSubview:audioButton];
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"Play";
    
    BOOL hasTranslatedText = result.translatedText.length > 0;
    audioButton.enabled = hasTranslatedText;
    
    [audioButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"audioActionBlock");
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(self.copiedText, nil);
        }
    }];
    audioButton.mas_key = @"audioButton";
    
    
    EZHoverButton *textCopyButton = [[EZHoverButton alloc] init];
    [self addSubview:textCopyButton];
    
    textCopyButton.image = [NSImage imageNamed:@"copy"];
    textCopyButton.toolTip = @"Copy";
    textCopyButton.enabled = hasTranslatedText;
    
    [textCopyButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"copyActionBlock");
        mm_strongify(self);
        if (self.copyTextBlock) {
            self.copyTextBlock(self.copiedText);
        }
    }];
    textCopyButton.mas_key = @"copyButton";
    
    CGFloat kMargin_8 = 8;
    CGFloat kRightMargin = 3;
    
    [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.top.equalTo(lastView.mas_bottom).offset(kMargin_8);
        } else {
            make.top.equalTo(self).offset(kMargin_8);
        }
        
        make.left.offset(kMargin_8);
        make.width.height.mas_equalTo(EZAudioButtonWidth_25);
    }];
    lastView = audioButton;
    
    height += (kMargin_8 + EZAudioButtonWidth_25 + 5);
    
    _viewHeight = height;
    
    //    NSLog(@"word result view height: %.1f", height);
    
    [textCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(audioButton.mas_right).offset(kRightMargin);
        make.width.height.bottom.equalTo(audioButton);
    }];
    
    
    EZLinkButton *linkButton = [[EZLinkButton alloc] init];
    [self addSubview:linkButton];
    
    NSImage *linkImage = [NSImage imageWithSystemSymbolName:@"link" accessibilityDescription:nil];
    linkImage = [linkImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_15, EZAudioButtonImageWidth_15)];
    linkButton.image = linkImage;
    linkButton.toolTip = @"Link";
    linkButton.link = [result.service wordLink:result.queryModel];
    
    [linkButton excuteLight:^(NSButton *linkButton) {
        linkButton.image = [linkImage imageWithTintColor:[NSColor imageTintLightColor]];
    } drak:^(NSButton *linkButton) {
        linkButton.image = [linkImage imageWithTintColor:[NSColor imageTintDarkColor]];
    }];
    linkButton.mas_key = @"linkButton";
    
    [linkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(textCopyButton.mas_right).offset(kRightMargin);
        make.width.height.bottom.equalTo(audioButton);
    }];
}

- (void)updateTagButton:(NSButton *)tagButton tagColor:(NSColor *)tagColor {
    tagButton.wantsLayer = YES;
    tagButton.layer.borderWidth = 1.2;
    tagButton.layer.cornerRadius = 3;
    tagButton.layer.borderColor = tagColor.CGColor;
    tagButton.bordered = NO;
    
    NSAttributedString *attributedString = [NSAttributedString mm_attributedStringWithString:tagButton.title font:[NSFont systemFontOfSize:12] color:tagColor];
    tagButton.attributedTitle = attributedString;
}

- (CGSize)labelSize:(EZLabel *)label exceptedWidth:(CGFloat)exceptedWidth {
    // ???: 很奇怪，比如实际计算结果为 364，但界面渲染却是 364.5 😑
    
    NSWindow *window = [self windowOfType:self.result.service.windowType];
    CGFloat selfWidth = window ? window.width - EZHorizontalCellSpacing_12 * 2 : self.width;
    CGFloat width = selfWidth - exceptedWidth;
    //        NSLog(@"text: %@, width: %@", label.text, @(width));
    //        NSLog(@"self.width: %@, selfWidth: %@", @(self.width), @(selfWidth));
    
    CGFloat height = [label getHeightWithWidth:width]; // 397 ?
    //    NSLog(@"height: %@", @(height));
    
    //    height = [label getTextViewHeightWithWidth:width]; // 377
    //    NSLog(@"height: %@", @(height));
    
    return CGSizeMake(width, height);
}

// Get window from the windows stack with window type.
- (EZBaseQueryWindow *)windowOfType:(EZWindowType)windowType {
    NSArray *windows = [[NSApplication sharedApplication] windows];
    for (EZBaseQueryWindow *window in windows) {
        if ([window isKindOfClass:[EZBaseQueryWindow class]] && window.windowType == windowType) {
            return window;
        }
    }
    return nil;
}

- (NSString *)copiedText {
    return self.result.translatedText;
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    // escape key
    if (commandSelector == @selector(cancelOperation:)) {
        //        NSLog(@"escape: %@", textView);
        [[EZWindowManager shared] closeFloatingWindow];
        return NO;
    }
    return NO;
}

#pragma mark -

// Convert text to multiple lines, such as "Hello world" to "Hello\nworld"
- (NSString *)multipleLineText:(NSString *)text font:(NSFont *)font lineWidth:(CGFloat)width {
    NSMutableString *result = [NSMutableString string];
    NSArray *words = [text componentsSeparatedByString:@" "];
    NSString *line = @"";
    for (NSString *word in words) {
        // Append the word to the current line
        NSString *temp = [line stringByAppendingFormat:@"%@ ", word];
        // Calculate the width of the line
        NSDictionary *attributes = @{NSFontAttributeName : font};
        CGRect rect = [temp boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
        CGFloat lineWidth = rect.size.width;
        // If the line width is greater than the max width, add a newline character and start a new line
        if (lineWidth > width) {
            [result appendFormat:@"%@\n", line];
            line = [NSString stringWithFormat:@"%@ ", word];
        } else {
            line = temp;
        }
    }
    // Append the last line
    [result appendString:line];
    return result;
}

@end
