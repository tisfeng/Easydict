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
#import "EZOpenLinkButton.h"
#import "NSImage+EZResize.h"
#import "EZQueryService.h"
#import "EZBlueTextButton.h"
#import "EZMyLabel.h"
#import "EZAudioButton.h"
#import "EZCopyButton.h"
#import "NSImage+EZSymbolmage.h"
#import <WebKit/WebKit.h>

static const CGFloat kHorizontalMargin_8 = 8;
static const CGFloat kVerticalMargin_12 = 12;
static const CGFloat kVerticalPadding_8 = 8;

@interface EZWordResultView () <NSTextViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) EZQueryResult *result;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, assign) CGFloat bottomViewHeigt;

@property (nonatomic, copy) NSString *copiedText;

@end


@implementation EZWordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = EZCornerRadius_8;
        [self.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_resultViewBgLightColor].CGColor;
        } dark:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_resultViewBgDarkColor].CGColor;
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
    NSColor *typeTextColor = [NSColor mm_colorWithHexString:@"#7A7A7A"];
    NSFont *typeTextFont = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    NSFont *textFont = typeTextFont;
    
    NSString *errorDescription = result.error.localizedDescription;
    if (result.errorMessage.length) {
        BOOL isOpenAI = [result.serviceType isEqualToString:EZServiceTypeOpenAI];
        NSString *joinedString = isOpenAI ? @"\n\n" : @"";
        errorDescription = [errorDescription stringByAppendingFormat:@"%@%@", joinedString, result.errorMessage];
        
        if (!errorDescription && !result.hasTranslatedResult) {
            errorDescription = result.errorMessage;
        }
    }
    
    mm_weakify(self);
    __block CGFloat ezLabelTopOffset = 0;
    
    BOOL isWordLength = result.queryText.length && result.queryText.length <= EZEnglishWordMaxLength;
    BOOL showBigWord = result.wordResult || result.showBigWord;
    if (isWordLength && showBigWord) {
        EZLabel *bigWordLabel = [[EZLabel alloc] init];
        [self addSubview:bigWordLabel];
        bigWordLabel.font = [NSFont systemFontOfSize:24 weight:NSFontWeightSemibold];
        bigWordLabel.text = result.queryText;
        
        [bigWordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(kHorizontalMargin_8);
            CGFloat topOffset = 8;
            height += (topOffset + bigWordLabel.height);
            if (lastView) {
                make.top.equalTo(lastView.mas_bottom).offset(topOffset);
            } else {
                make.top.offset(topOffset);
            }
            
            CGSize labelSize = [bigWordLabel oneLineSize];
            make.size.mas_equalTo(labelSize).priorityHigh();
        }];
        
        bigWordLabel.mas_key = @"wordTextField";
        lastView = bigWordLabel;
    }
    
    if (result.translatedResults.count || errorDescription.length > 0 || result.noResultsFound) {
        EZLabel *explainLabel;
        __block CGFloat exceptedWidth = 0;
        CGFloat explainTextFieldTopOffset = 9;
        if (lastView) {
            explainTextFieldTopOffset += 5;
        }
        
        if (result.wordResult && result.translatedResults.count) {
            explainLabel = [[EZLabel alloc] init];
            [self addSubview:explainLabel];
            explainLabel.font = typeTextFont;
            explainLabel.textForegroundColor = typeTextColor;
            explainLabel.text = NSLocalizedString(@"explain", nil);
            
            CGSize labelSize = [explainLabel oneLineSize];
            
            [explainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(explainTextFieldTopOffset);
                } else {
                    make.top.offset(explainTextFieldTopOffset);
                }
                make.left.mas_equalTo(kHorizontalMargin_8);
                exceptedWidth += kHorizontalMargin_8;
                
                make.size.mas_equalTo(labelSize).priorityHigh();
                exceptedWidth += ceil(labelSize.width);
            }];
            explainLabel.mas_key = @"explainLabel";
        }
        
        NSString *text = nil;
        if (result.translatedText.length > 0) {
            text = result.translatedText;
        } else if (!result.wordResult && errorDescription.length) {
            text = errorDescription;
        } else if (!result.hasTranslatedResult) {
            text = NSLocalizedString(@"no_results_found", nil);
        }
        
        if (text.length) {
            EZLabel *resultLabel = [[EZLabel alloc] init];
            [self addSubview:resultLabel];
            
            // OpenAI result text has its own paragraph style.
            if ([result.serviceType isEqualToString:EZServiceTypeOpenAI]) {
                resultLabel.paragraphSpacing = 0;
            }
            
            resultLabel.text = text;
            resultLabel.delegate = self;
            
            [resultLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                CGFloat rightOffset = kHorizontalMargin_8;
                make.right.equalTo(self).offset(-rightOffset);
                exceptedWidth += rightOffset;
                
                CGFloat topOffset = explainTextFieldTopOffset + result.translateResultsTopInset;
                
                if (!explainLabel) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                    } else {
                        make.top.equalTo(self).offset(topOffset);
                    }
                    
                    CGFloat leftPadding = kHorizontalMargin_8;
                    exceptedWidth += leftPadding;
                    make.left.equalTo(self).offset(leftPadding);
                }
                
                CGSize labelSize = [self labelSize:resultLabel exceptedWidth:exceptedWidth];
                make.size.mas_equalTo(labelSize).priorityHigh();
                
                // ???: This means the label text has more than 2 lines, so we need to adjust the top offset.
                if (labelSize.height > explainLabel.height * 2) {
                    //                    ezLabelTopOffset = -1;
                }
                
                if (explainLabel) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(topOffset + ezLabelTopOffset);
                    } else {
                        make.top.equalTo(self).offset(topOffset);
                    }
                    make.left.equalTo(explainLabel.mas_right);
                }
                
                height += (topOffset + labelSize.height);
                // NSLog(@"height = %1.f", height);
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
    
    if (result.HTMLString.length) {
        NSLog(@"load webView");
        WKWebView *webView = [[WKWebView alloc] init];
        [self addSubview:webView];
        [webView loadHTMLString:result.HTMLString baseURL:nil];
        webView.navigationDelegate = self;
        self.webView = webView;
        
        [webView mas_makeConstraints:^(MASConstraintMaker *make) {
            CGFloat topOffset = 0;
            if (lastView) {
                topOffset = kHorizontalMargin_8;
                make.top.equalTo(lastView.mas_bottom).offset(topOffset);
                height += topOffset;
            } else {
                make.top.offset(topOffset);
            }
            height += topOffset;
            make.left.right.inset(2);
        }];
        
        lastView = webView;
    }
    
    [wordResult.phonetics enumerateObjectsUsingBlock:^(EZWordPhonetic *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        EZLabel *phoneticTagLabel = [[EZLabel alloc] init];
        [self addSubview:phoneticTagLabel];
        phoneticTagLabel.font = typeTextFont;
        phoneticTagLabel.textForegroundColor = typeTextColor;
        phoneticTagLabel.text = obj.name;
        
        [phoneticTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(kHorizontalMargin_8);
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
            CGSize labelSize = [phoneticTagLabel oneLineSize];
            make.size.mas_equalTo(labelSize).priorityHigh();
            height += labelSize.height;
        }];
        phoneticTagLabel.mas_key = @"phoneticsLabel";
        lastView = phoneticTagLabel;
        
        // 部分没有音标文本
        EZLabel *phoneticLabel = nil;
        if (obj.value.length) {
            phoneticLabel = [[EZLabel alloc] init];
            [self addSubview:phoneticLabel];
            phoneticLabel.textContainer.lineFragmentPadding = 0;
            phoneticLabel.font = [NSFont systemFontOfSize:textFont.pointSize];
            
            // ???: WTF, why Baidu phonetic contain '\n', e.g. ceil "siːl\n"
            NSString *phonetic = [obj.value trim];
            phoneticLabel.text = [NSString stringWithFormat:@"/ %@ /", phonetic];
            [phoneticLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(phoneticTagLabel.mas_right).offset(kHorizontalMargin_8);
                make.centerY.equalTo(phoneticTagLabel);
                
                CGSize labelSize = [phoneticLabel oneLineSize];
                make.size.mas_equalTo(labelSize).priorityHigh();
            }];
            
            phoneticLabel.mas_key = @"phoneticLabel";
        }
        
        EZAudioButton *audioButton = [[EZAudioButton alloc] init];
        [self addSubview:audioButton];
        
        EZAudioPlayer *audioPlayer = [[EZAudioPlayer alloc] init];
        audioPlayer.service = result.service;
        audioButton.audioPlayer = audioPlayer;
        [audioButton setPlayAudioBlock:^{
            [audioPlayer playWordPhonetic:obj serviceType:result.serviceType];
        }];
        
        [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
            NSView *leftView = phoneticLabel ?: phoneticTagLabel;
            make.left.equalTo(leftView.mas_right).offset(5);
            make.centerY.equalTo(phoneticLabel ?: phoneticTagLabel);
            make.width.height.mas_equalTo(23);
        }];
        audioButton.mas_key = @"audioButton_phonetics";
    }];
    
    EZLabel *tagLabel = nil;
    __block NSScrollView *tagScrollView = nil;
    if (wordResult.tags.count) {
        tagLabel = [[EZLabel alloc] init];
        [self addSubview:tagLabel];
        tagLabel.font = typeTextFont;
        tagLabel.textForegroundColor = typeTextColor;
        tagLabel.text = NSLocalizedString(@"tag", nil);
        
        CGSize labelSize = [tagLabel oneLineSize];
        
        [tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(kHorizontalMargin_8);
            CGFloat topOffset = kVerticalMargin_12 + 3;
            if (lastView) {
                make.top.equalTo(lastView.mas_bottom).offset(topOffset);
            } else {
                make.top.offset(topOffset);
            }
            height += topOffset;
            
            make.size.mas_equalTo(labelSize).priorityHigh();
            height += labelSize.height;
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
                NSColor *tagColor = [NSColor mm_colorWithHexString:@"#7A7A78"];
                [self updateTagButton:tagButton tagColor:tagColor];
            } dark:^(NSButton *tagButton) {
                NSColor *tagColor = [NSColor mm_colorWithHexString:@"#CCCCC8"];
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
                    layer.backgroundColor = [NSColor ez_resultViewBgLightColor].CGColor;
                } dark:^(CALayer *layer) {
                    layer.backgroundColor = [NSColor ez_resultViewBgDarkColor].CGColor;
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
        
        CGFloat maxTagScrollViewWidth = self.width - (kHorizontalMargin_8 + labelSize.width + padding * 2);
        CGFloat tagScrollViewWidth = MIN(tagContentViewWidth, maxTagScrollViewWidth);
        [tagScrollView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(tagScrollViewWidth);
        }];
    }
    
    [wordResult.parts enumerateObjectsUsingBlock:^(EZTranslatePart *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        EZLabel *partLabel = nil;
        __block CGFloat exceptedWidth = 0;
        if (obj.part.length) {
            partLabel = [[EZLabel alloc] init];
            [self addSubview:partLabel];
            partLabel.font = typeTextFont;
            partLabel.textForegroundColor = typeTextColor;
            partLabel.text = obj.part;
            
            [partLabel mas_makeConstraints:^(MASConstraintMaker *make) {
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
                
                CGSize labelSize = [partLabel oneLineSize];
                make.size.mas_equalTo(labelSize).priorityHigh();
            }];
            partLabel.mas_key = @"partLabel";
        }
        
        EZLabel *meanLabel = [[EZLabel alloc] init];
        [self addSubview:meanLabel];
        NSString *text = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
        meanLabel.text = text;
        meanLabel.delegate = self;
        
        exceptedWidth += ceil(partLabel.width);
        
        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
            
            if (partLabel) {
                make.top.equalTo(partLabel);
                CGFloat leftLeading = 2;
                make.left.equalTo(partLabel.mas_right).offset(leftLeading);
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
            if (labelSize.height < partLabel.height) {
                labelSize.height = partLabel.height;
            }
            
            make.size.mas_equalTo(labelSize).priorityHigh();
            
            height += labelSize.height;
            //            NSLog(@"height = %1.f", height);
        }];
        meanLabel.mas_key = @"meanTextField_parts";
        lastView = meanLabel;
    }];
    
    [wordResult.exchanges enumerateObjectsUsingBlock:^(EZTranslateExchange *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        EZLabel *exchangeLabel = [[EZLabel alloc] init];
        [self addSubview:exchangeLabel];
        exchangeLabel.font = typeTextFont;
        exchangeLabel.textForegroundColor = typeTextColor;
        exchangeLabel.text = [NSString stringWithFormat:@"%@:", obj.name];
        
        [exchangeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(kHorizontalMargin_8);
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
            
            CGSize labelSize = [exchangeLabel oneLineSize];
            make.size.mas_equalTo(labelSize).priorityHigh();
            height += labelSize.height;
        }];
        exchangeLabel.mas_key = @"exchangeLabel";
        lastView = exchangeLabel;
        
        __block EZBlueTextButton *lastWordButton = nil;
        [obj.words enumerateObjectsUsingBlock:^(NSString *_Nonnull word, NSUInteger idx, BOOL *_Nonnull stop) {
            EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
            [self addSubview:wordButton];
            [wordButton setTitle:word];
            
            [wordButton mas_makeConstraints:^(MASConstraintMaker *make) {
                if (!lastWordButton) {
                    make.left.equalTo(exchangeLabel.mas_right);
                } else {
                    make.left.equalTo(lastWordButton.mas_right).offset(3);
                }
                make.centerY.equalTo(exchangeLabel);
            }];
            mm_weakify(self);
            [wordButton setClickBlock:^(EZButton *_Nonnull button) {
                mm_strongify(self);
                if (self.queryTextBlock) {
                    self.queryTextBlock(word);
                }
                [word copyToPasteboard];
            }];
            wordButton.mas_key = @"wordButton_words";
            lastWordButton = wordButton;
        }];
    }];
    
    __block NSString *lastSimpleWordPart = nil;
    [wordResult.simpleWords enumerateObjectsUsingBlock:^(EZTranslateSimpleWord *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        EZLabel *partLabel = nil;
        if (!obj.showPartMeans && obj.part.length && (!lastSimpleWordPart || ![obj.part isEqualToString:lastSimpleWordPart])) {
            partLabel = [[EZLabel alloc] init];
            [self addSubview:partLabel];
            partLabel.font = typeTextFont;
            partLabel.textForegroundColor = typeTextColor;
            partLabel.text = obj.part;
            
            [partLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin_8);
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                } else {
                    make.top.offset(kVerticalPadding_8);
                }
                height += kVerticalPadding_8;
                
                CGSize labelSize = [partLabel oneLineSize];
                make.size.mas_equalTo(labelSize).priorityHigh();
                height += labelSize.height;
            }];
            partLabel.mas_key = @"partLabel_simpleWords";
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
            if (partLabel) {
                CGFloat topOffset = 3;
                height += topOffset;
                make.top.equalTo(partLabel.mas_bottom).offset(topOffset);
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
            if (self.queryTextBlock) {
                self.queryTextBlock(obj.word);
            }
            [obj.word copyToPasteboard];
        }];
        wordButton.mas_key = @"wordButton_simpleWords";
        
        
        EZLabel *meanLabel = [[EZLabel alloc] init];
        meanLabel.text = obj.meansText;
        
        [self addSubview:meanLabel];
        [meanLabel excuteLight:^(id _Nonnull x) {
            [x setTextColor:[NSColor ez_resultTextLightColor]];
        } dark:^(id _Nonnull x) {
            [x setTextColor:[NSColor ez_resultTextDarkColor]];
        }];
        
        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            CGFloat topOffset = wordButton.expandValue / 2; // expandValue = 6;
            make.top.equalTo(wordButton).offset(topOffset); // Since word button has expand vlaue
            
            CGFloat leftOffset = 4;
            make.left.equalTo(wordButton.mas_right).offset(leftOffset);
            exceptedWidth += leftOffset;
            
            CGFloat rightOffset = 5;
            make.right.lessThanOrEqualTo(self).offset(-rightOffset);
            exceptedWidth += rightOffset;
            
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
        
        EZLabel *etymologyLabel = [[EZLabel alloc] init];
        [self addSubview:etymologyLabel];
        etymologyLabel.font = typeTextFont;
        etymologyLabel.textForegroundColor = typeTextColor;
        etymologyLabel.text = NSLocalizedString(@"etymology", nil);
        
        [etymologyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            if (lastView) {
                make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
            } else {
                make.top.offset(kVerticalMargin_12);
            }
            make.left.mas_equalTo(kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
            
            CGSize labelSize = [etymologyLabel oneLineSize];
            make.size.mas_equalTo(labelSize).priorityHigh();
            height += labelSize.height;
            exceptedWidth += ceil(labelSize.width);
        }];
        etymologyLabel.mas_key = @"etymologyLabel";
        lastView = etymologyLabel;
        
        
        EZLabel *resultLabel = [[EZLabel alloc] init];
        [self addSubview:resultLabel];
        resultLabel.text = wordResult.etymology;
        resultLabel.delegate = self;
        
        [resultLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
            
            if (etymologyLabel) {
                make.top.equalTo(etymologyLabel);
                make.left.equalTo(etymologyLabel.mas_right);
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
    
    EZAudioButton *audioButton = [[EZAudioButton alloc] init];
    [self addSubview:audioButton];
    
    BOOL hasTranslatedText = result.translatedText.length > 0;
    audioButton.enabled = hasTranslatedText;
    
    audioButton.audioPlayer = self.result.service.audioPlayer;
    
    [audioButton setPlayStatus:^(BOOL isPlaying, EZAudioButton *audioButton) {
        NSString *action = isPlaying ? NSLocalizedString(@"stop_play_audio", nil) : NSLocalizedString(@"play_audio", nil);
        audioButton.toolTip = [NSString stringWithFormat:@"%@", action];
    }];
    
    [audioButton setPlayAudioBlock:^{
        mm_strongify(self);
        EZWordPhonetic *wordPhonetic = [[EZWordPhonetic alloc] init];
        wordPhonetic.word = self.copiedText;
        
        EZLanguage language = result.queryModel.queryTargetLanguage;
        if ([result.serviceType isEqualToString:EZServiceTypeOpenAI]) {
            language = result.to;
        }
        
        wordPhonetic.language = language;
        [result.service.audioPlayer playWordPhonetic:wordPhonetic serviceType:result.serviceType];
    }];
    
    audioButton.mas_key = @"result_audioButton";
    
    EZCopyButton *textCopyButton = [[EZCopyButton alloc] init];
    [self addSubview:textCopyButton];
    textCopyButton.enabled = hasTranslatedText | result.HTMLString.length;
    
    [textCopyButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"copyActionBlock");
        mm_strongify(self);
        [self.copiedText copyAndShowToast:YES];
    }];
    textCopyButton.mas_key = @"result_copyButton";
    
    CGFloat audioButtonLeftOffset = EZAudioButtonLeftMargin_6;
    CGFloat audioButtonTopOffset = 6;
    CGFloat buttonPadding = EZAudioButtonRightPadding_1;
    
    [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.top.equalTo(lastView.mas_bottom).offset(audioButtonTopOffset);
        } else {
            make.top.equalTo(self).offset(audioButtonTopOffset);
        }
        
        make.left.offset(audioButtonLeftOffset);
        make.width.height.mas_equalTo(EZAudioButtonWidthHeight_24);
    }];
    lastView = audioButton;
    
    self.bottomViewHeigt = audioButtonTopOffset + EZAudioButtonWidthHeight_24 + EZAudioButtonBottomMargin_4;
    
    height += self.bottomViewHeigt;
    _viewHeight = height;
    //    NSLog(@"word result view height: %.1f", height);
    
    
    [textCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(audioButton.mas_right).offset(buttonPadding);
        make.width.height.bottom.equalTo(audioButton);
    }];
    
    EZOpenLinkButton *linkButton = [[EZOpenLinkButton alloc] init];
    [self addSubview:linkButton];
    
    NSImage *linkImage = [NSImage ez_imageWithSymbolName:@"link"];
    linkButton.image = linkImage;
    linkButton.toolTip = NSLocalizedString(@"open_web_link", nil);
    linkButton.link = [result.service wordLink:result.queryModel];
    
    [linkButton excuteLight:^(NSButton *linkButton) {
        linkButton.image = [linkButton.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *linkButton) {
        linkButton.image = [linkButton.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];
    linkButton.mas_key = @"result_linkButton";
    
    [linkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(textCopyButton.mas_right).offset(buttonPadding);
        make.width.height.bottom.equalTo(audioButton);
    }];
    
    // webView height need time to calculate, and the value will be called back later.
    if (result.serviceType == EZServiceTypeAppleDictionary) {
        BOOL hasHTML = result.HTMLString.length > 0;
        linkButton.enabled = hasHTML;
        
        if (hasHTML) {
            _viewHeight = 0;
        }
    }
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
    
    CGFloat height = [label ez_getTextViewHeightDesignatedWidth:width]; // 397 ?
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
    if (!_copiedText) {
        // TODO: copy word dictionary text.
        _copiedText = self.result.translatedText;
        
        if (!_copiedText.length && self.result.HTMLString.length) {
            [self fetchAllWebViewText];
        }
    }
    return _copiedText;
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


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // Cost ~0.15s
    NSLog(@"loaded webView");
    NSString *script = @"document.body.scrollHeight;";
    
    mm_weakify(self);
    
    [webView evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (!error) {
            mm_strongify(self);
            
            // Cost ~0.2s
            CGFloat contentHeight = [result doubleValue];
            NSLog(@"contentHeight: %.1f", contentHeight);
            
            CGFloat maxHeight = EZLayoutManager.shared.screen.visibleFrame.size.height * 0.5;
            
            // Fix strange white line
            CGFloat webViewHeight = ceil(MIN(maxHeight, contentHeight));
            CGFloat viewHeight = self.bottomViewHeigt + webViewHeight;
            
            // Fix scrollable height.
            NSMutableString *jsCode = [self jsCodeOfUpdateStyleHeight:webViewHeight].mutableCopy;
            if (contentHeight > maxHeight) {
                [jsCode appendString:[self jsCodeOfOptimizeScrollableWebView]];
                ;
            }
            [self evaluateJavaScript:jsCode];
            
            [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(webViewHeight);
            }];
            
            // !!!: Must update view height, then update cell height.
            if (self.updateViewHeightBlock) {
                self.updateViewHeightBlock(viewHeight);
            }
            
            [EZWindowManager.shared.floatingWindow.queryViewController updateCellWithResult:self.result reloadData:NO];
            
            if (self.didFinishLoadingHTMLBlock) {
                self.didFinishLoadingHTMLBlock();
            }
            
        } else {
            NSLog(@"Error evaluating JavaScript: %@", error.localizedDescription);
        }
    }];
    
//    [webView excuteLight:^(WKWebView *webView) {
//        mm_strongify(self);
//        [self updateWebViewBackgroundColorWithDarkMode:NO];
//    } dark:^(WKWebView *webView) {
//        mm_strongify(self);
//        [self updateWebViewBackgroundColorWithDarkMode:YES];
//    }];
}

- (void)updateWebViewBackgroundColorWithDarkMode:(BOOL)isDark {
    NSString *lightTextColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextLightColor]];
    NSString *lightBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgLightColor]];
    
    NSString *darkTextColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultTextDarkColor]];
    NSString *darkBackgroundColorString = [NSColor mm_hexStringFromColor:[NSColor ez_resultViewBgDarkColor]];
    
    NSString *textColorString = isDark ? darkTextColorString : lightTextColorString;
    NSString *backgroundColorString = isDark ? darkBackgroundColorString : lightBackgroundColorString;
    
    NSString *updateBodyColorJSCode = [self jsCodeOfUpdateBodyTextColor:textColorString backgroundColor:backgroundColorString];
   NSString *updateIframeColorJSCode = [self jsCodeOfUpdateAllIframeTextColor:textColorString backgroundColor:backgroundColorString];
    
    NSString *jsCode = [NSString stringWithFormat:@"%@ %@", updateBodyColorJSCode, updateIframeColorJSCode];
    
    [self evaluateJavaScript:jsCode];
}


- (NSString *)jsCodeOfUpdateAllIframeTextColor:(NSString *)color backgroundColor:(NSString *)backgroundColor {
    NSString *jsCode = [NSString stringWithFormat:@""
    "var iframes = document.querySelectorAll('iframe');"
    "for (var i = 0; i < iframes.length; i++) {"
    "   iframes[i].contentDocument.body.style.webkitTextFillColor = '%@';"
    "   iframes[i].contentDocument.body.style.backgroundColor = '%@';"
    "};", color, backgroundColor];
    
    return jsCode;;
}

- (NSString *)jsCodeOfUpdateBodyTextColor:(NSString *)color backgroundColor:(NSString *)backgroundColor {
    NSString *jsCode = [NSString stringWithFormat:@""
                        @"document.body.style.webkitTextFillColor='%@';"
                        @"document.body.style.backgroundColor='%@';"
                        , color, backgroundColor];
    
    return jsCode;;
}

- (NSString *)jsCodeOfUpdateStyleHeight:(CGFloat)height {
    NSString *jsCode = [NSString stringWithFormat:@"document.body.style.height = '%fpx';", height];
    return jsCode;
}

- (NSString *)jsCodeOfOptimizeScrollableWebView {
    NSString *appendBlankLine = @"var div = document.createElement('div');"
    @"div.style.height = '1px';"
    @"document.body.appendChild(div);"
    @"0;";
    
    NSString *showScrollbarBriefly = @"window.scrollTo(0, 1);"
    @"setTimeout(function () { window.scrollTo(0, 0); }, 0);";
    
    NSString *jsCode = [NSString stringWithFormat:@"%@ %@", appendBlankLine, showScrollbarBriefly];
    return jsCode;
}


- (void)evaluateJavaScript:(NSString *)jsCode {
    [self evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (error) {
            NSLog(@"error: %@", error);
            NSLog(@"jsCode: %@", jsCode);
        } else {
            NSLog(@"result: %@", result);
        }
    }];
}

- (void)evaluateJavaScript:(NSString *)jsCode completionHandler:(void (^_Nullable)(_Nullable id, NSError *_Nullable error))completionHandler {
    [self.webView evaluateJavaScript:jsCode completionHandler:completionHandler];
}

- (void)fetchAllWebViewText {
    NSString *jsCode = @"document.body.innerText;";
    [self.webView evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (!error && [result isKindOfClass:[NSString class]]) {
            NSString *webViewText = (NSString *)result;
            self.copiedText = webViewText;
            [webViewText copyAndShowToast:YES];
        }
    }];
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
