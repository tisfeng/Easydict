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
#import "TTTDictionary.h"
#import "EZConfiguration.h"
#import "EZServiceTypes.h"
#import "EZAppleService.h"
#import "EZReplaceTextButton.h"
#import "EZWrapView.h"
#import "Easydict-Swift.h"

static const CGFloat kHorizontalMargin_8 = 8;
static const CGFloat kVerticalMargin_12 = 12;
static const CGFloat kVerticalPadding_6 = 6;
static const CGFloat kBlueTextButtonVerticalPadding_2 = 2;

static NSString *const kAppleDictionaryURIScheme = @"x-dictionary";

@interface EZWordResultView () <NSTextViewDelegate>

@property (nonatomic, strong) EZQueryResult *result;
@property (nonatomic, strong) NSButton *replaceTextButton;

@property (nonatomic, assign) CGFloat bottomViewHeight;

@property (nonatomic, assign) CGFloat fontSizeRatio;

@end


@implementation EZWordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = EZCornerRadius_8;
        self.fontSizeRatio = EZConfiguration.shared.fontSizeRatio;
        [self.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_resultViewBgLightColor].CGColor;
        } dark:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_resultViewBgDarkColor].CGColor;
        }];
    }
    return self;
}

// TODO: This method is too long, need to refactor.
- (void)refreshWithResult:(EZQueryResult *)result {
    self.result = result;
    self.fontSizeRatio = EZConfiguration.shared.fontSizeRatio;

    EZTranslateWordResult *wordResult = result.wordResult;
    self.webView = result.webViewManager.webView;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    __block CGFloat height = 0;
    __block NSView *lastView = nil;
    NSColor *typeTextColor = [NSColor mm_colorWithHexString:@"#7A7A7A"];
    NSFont *typeTextFont = [NSFont systemFontOfSize:13 * self.fontSizeRatio weight:NSFontWeightMedium];
    NSFont *textFont = typeTextFont;
    
    EZError *error = result.error;
    NSString *errorDescription = error.localizedDescription;
    NSString *errorDataMessage = error.errorDataMessage;
    if (errorDataMessage.length) {
        errorDescription = [errorDescription stringByAppendingFormat:@"\n\n%@", errorDataMessage];
        if (!errorDescription && !result.hasTranslatedResult) {
            errorDescription = errorDataMessage;
        }
    }
    
    mm_weakify(self);
    
    __block CGFloat ezLabelTopOffset = 0;
    
    BOOL isShortWordLength = result.queryText.length && [EZLanguageManager.shared isShortWordLength:result.queryText language:result.queryFromLanguage];
    
    BOOL showBigWord = result.wordResult || result.showBigWord;
    if (isShortWordLength && showBigWord) {
        EZLabel *bigWordLabel = [[EZLabel alloc] init];
        [self addSubview:bigWordLabel];
        bigWordLabel.font = [NSFont systemFontOfSize:24 * self.fontSizeRatio weight:NSFontWeightSemibold];
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
    
    if (result.translatedResults.count || errorDescription.length > 0) {
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
        if (result.translatedText) {
            text = result.translatedText;
        } else if (!result.wordResult && errorDescription.length) {
            text = errorDescription;
        } else if (!result.hasTranslatedResult) {
            text = NSLocalizedString(@"no_results_found", nil);
        }
        
        if (text) {
            EZLabel *resultLabel = [[EZLabel alloc] init];
            resultLabel.font = [NSFont systemFontOfSize:14 * self.fontSizeRatio];
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
        
        if (result.promptURL.length) {
            NSTextField *promptTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
                [self addSubview:textField];
                textField.stringValue = NSLocalizedString(@"please_look", nil);
                textField.font = [NSFont systemFontOfSize:14 * self.fontSizeRatio];
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
            
            NSString *title = result.promptTitle.length ? result.promptTitle : result.promptURL;
            [promptButton setTitle:title];
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
        [self addSubview:self.webView];
        
        if (result.webViewManager.isLoaded) {
            [result.webViewManager updateAllIframe];
        }
        
        [result.webViewManager setDidFinishUpdatingIframeHeightBlock:^(CGFloat scrollHeight) {
            mm_strongify(self);
            
            [self updateWebViewHeight:scrollHeight];
        }];
        
        
        [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
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
        
        lastView = self.webView;
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
                    height += kVerticalPadding_6;
                }
            } else {
                CGFloat topOffset = kVerticalPadding_6;
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
        
        // Fix: SIGABRT: -[NSNull length]: unrecognized selector sent to instance 0x7ff85c514b40
        NSString *phonetic = obj.value;
        if ([phonetic isKindOfClass:NSString.class] && phonetic.length) {
            phoneticLabel = [[EZLabel alloc] init];
            [self addSubview:phoneticLabel];
            phoneticLabel.textContainer.lineFragmentPadding = 0;
            phoneticLabel.font = [NSFont systemFontOfSize:textFont.pointSize * self.fontSizeRatio];
            
            // ???: WTF, why Baidu phonetic contain '\n', e.g. ceil "siːl\n"
            phoneticLabel.text = [NSString stringWithFormat:@"/ %@ /", phonetic.trim];
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
        audioButton.audioPlayer = audioPlayer;
        [audioButton setPlayAudioBlock:^{
            [audioPlayer playWordPhonetic:obj designatedService:result.service];
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
                    CGFloat topOffset = kVerticalPadding_6;
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
                
                exceptedWidth += ceil(labelSize.width);
            }];
            partLabel.mas_key = @"partLabel";
        }
        
        EZLabel *meanLabel = [[EZLabel alloc] init];
        meanLabel.font = [NSFont systemFontOfSize:14 * self.fontSizeRatio];
        [self addSubview:meanLabel];
        NSString *text = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
        meanLabel.text = text;
        meanLabel.delegate = self;
        
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
                    CGFloat topPadding = kVerticalPadding_6;
                    if (idx == 0) {
                        topPadding = kVerticalMargin_12;
                    }
                    make.top.equalTo(lastView.mas_bottom).offset(topPadding);
                    height += topPadding;
                    
                } else {
                    make.top.offset(kHorizontalMargin_8);
                    height += kVerticalPadding_6;
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
                CGFloat topPadding = kVerticalPadding_6;
                if (idx == 0) {
                    topPadding = kVerticalMargin_12;
                }
                make.top.equalTo(lastView.mas_bottom).offset(topPadding);
                height += topPadding;
            } else {
                make.top.offset(kVerticalPadding_6);
                height += kVerticalPadding_6;
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
            wordButton.fontSize = 14 * self.fontSizeRatio;
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
    
    // 同义词
    if (result.wordResult.synonyms.count) {
        lastView = [self buildSynonymsAndAntonymsView:NSLocalizedString(@"synonyms", nil) parts:result.wordResult.synonyms textColor:typeTextColor typeTextFont:typeTextFont height:&height lastView:lastView];
    }
    
    // 反义词
    if (result.wordResult.antonyms.count) {
        lastView = [self buildSynonymsAndAntonymsView:NSLocalizedString(@"antonyms", nil) parts:result.wordResult.antonyms textColor:typeTextColor typeTextFont:typeTextFont height:&height lastView:lastView];
    }
    
    // 搭配
    if (result.wordResult.collocation.count) {
        lastView = [self buildSynonymsAndAntonymsView:NSLocalizedString(@"collocation", nil) parts:result.wordResult.collocation textColor:typeTextColor typeTextFont:typeTextFont height:&height lastView:lastView];
    }
    
    __block NSString *lastSimpleWordPart = nil;
    NSArray *showingSimpleWords = [wordResult.simpleWords trimToMaxCount:EZMaxThreeWordPhraseCount];
    [showingSimpleWords enumerateObjectsUsingBlock:^(EZTranslateSimpleWord *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_6);
                } else {
                    make.top.offset(kVerticalPadding_6);
                }
                height += kVerticalPadding_6;
                
                CGSize labelSize = [partLabel oneLineSize];
                make.size.mas_equalTo(labelSize).priorityHigh();
                height += labelSize.height;
            }];
            partLabel.mas_key = @"partLabel_simpleWords";
            lastSimpleWordPart = obj.part;
        }
        
        __block CGFloat exceptedWidth = 0;
        
        EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
        wordButton.fontSize = 14 * self.fontSizeRatio;
        wordButton.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:wordButton];
        
        CGFloat maxButtonWidth = self.width / 2;
        NSString *title = [self multipleLineText:obj.word font:[NSFont systemFontOfSize:14 * self.fontSizeRatio] lineWidth:maxButtonWidth];
        [wordButton setTitle:title];
        
        CGSize buttonSize = wordButton.size;
        if (buttonSize.width > maxButtonWidth) {
            buttonSize.width = maxButtonWidth;
        }
        CGFloat buttonHeight = [wordButton.title mm_heightWithFont:[NSFont systemFontOfSize:14 * self.fontSizeRatio] constrainedToWidth:maxButtonWidth];
        
        buttonSize.height = buttonHeight + wordButton.expandValue;
        
        [wordButton mas_updateConstraints:^(MASConstraintMaker *make) {
            CGFloat leftOffset = kHorizontalMargin_8 - 2;
            exceptedWidth += leftOffset;
            make.left.offset(leftOffset); // Since button has been expanded, so need to be shifted to the left.
            if (partLabel) {
                CGFloat topOffset = kBlueTextButtonVerticalPadding_2;
                height += topOffset;
                make.top.equalTo(partLabel.mas_bottom).offset(topOffset);
            } else {
                CGFloat topOffset = kHorizontalMargin_8;
                if (lastView) {
                    topOffset = kBlueTextButtonVerticalPadding_2;
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
        meanLabel.font = [NSFont systemFontOfSize:14 * self.fontSizeRatio];
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
        resultLabel.font = [NSFont systemFontOfSize:14 * self.fontSizeRatio];
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
        NSString *text = result.copiedText;
        
        // For some special case, copied text language is not the queryTargetLanguage, like 龘, Youdao translate.
        EZLanguage language = [EZAppleService.shared detectText:text];
        if ([result.serviceType isEqualToString:EZServiceTypeOpenAI]) {
            language = result.to;
        }
        
        EZServiceType defaultTTSServiceType = EZConfiguration.shared.defaultTTSServiceType;
        EZQueryService *defaultTTSService = [EZServiceTypes.shared serviceWithType:defaultTTSServiceType];
        
        [result.service.audioPlayer playTextAudio:text
                                         language:language
                                           accent:nil
                                         audioURL:nil
                                designatedService:defaultTTSService];
    }];
    
    audioButton.mas_key = @"result_audioButton";
    
    EZCopyButton *textCopyButton = [[EZCopyButton alloc] init];
    [self addSubview:textCopyButton];
    textCopyButton.enabled = hasTranslatedText | result.HTMLString.length;
    
    [textCopyButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"copyActionBlock");
        [result.copiedText copyAndShowToast:YES];
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
    
    self.bottomViewHeight = audioButtonTopOffset + EZAudioButtonWidthHeight_24 + EZAudioButtonBottomMargin_4;
    
    height += self.bottomViewHeight;
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
    
    NSString *toolTip = NSLocalizedString(@"open_web_link", nil);
    if (result.serviceType == EZServiceTypeAppleDictionary) {
        toolTip = NSLocalizedString(@"open_in_apple_dictionary", nil);
    }
    linkButton.toolTip = toolTip;
    
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
    
    EZReplaceTextButton *replaceTextButton = [[EZReplaceTextButton alloc] init];
    [self addSubview:replaceTextButton];
    replaceTextButton.hidden = !result.showReplaceButton;
    replaceTextButton.enabled = hasTranslatedText;
    self.replaceTextButton = replaceTextButton;
    
    [replaceTextButton setClickBlock:^(EZButton *button) {
        NSString *replacedText = result.copiedText;
        EZReplaceTextButton *replaceTextButton = (EZReplaceTextButton *)button;
        [replaceTextButton replaceSelectedText:replacedText];
        
        EZBaseQueryViewController *queryViewController = EZWindowManager.shared.floatingWindow.queryViewController;
        [queryViewController disableReplaceTextButton];
    }];
    replaceTextButton.mas_key = @"replaceTextButton";
    
    [replaceTextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(linkButton.mas_right).offset(buttonPadding);
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

- (NSView *)buildSynonymsAndAntonymsView:(NSString *)title parts:(NSArray<EZTranslatePart *> *)parts textColor:(NSColor *)typeTextColor typeTextFont:(NSFont *)typeTextFont height:(CGFloat *)height lastView:(NSView *)lastView {
    __block NSView *rtnView = lastView;
    EZLabel *synonymsTitle = [[EZLabel alloc] init];
    [self addSubview:synonymsTitle];
    synonymsTitle.font = typeTextFont;
    synonymsTitle.textForegroundColor = typeTextColor;
    synonymsTitle.text = title;
    [synonymsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(kHorizontalMargin_8);
        if (rtnView) {
            CGFloat topPadding = kVerticalMargin_12;
            make.top.equalTo(rtnView.mas_bottom).offset(topPadding);
            *height += topPadding;
        } else {
            make.top.offset(kVerticalPadding_6);
            *height += kVerticalPadding_6;
        }
        
        CGSize labelSize = [synonymsTitle oneLineSize];
        make.size.mas_equalTo(labelSize).priorityHigh();
        *height += labelSize.height;
    }];
    rtnView = synonymsTitle;
    
    mm_weakify(self)
    [parts enumerateObjectsUsingBlock:^(EZTranslatePart * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.means.count == 0) return;
        EZLabel *partLabel = [[EZLabel alloc] init];
        partLabel.font = typeTextFont;
        partLabel.textForegroundColor = typeTextColor;
        partLabel.text = obj.part;
        [self addSubview:partLabel];
        
        EZWrapView *wrapView = [[EZWrapView alloc] init];
        [self addSubview:wrapView];
        
        NSArray *showingMeans = [obj.means trimToMaxCount:EZMaxFiveWordSynonymCount];
        [showingMeans enumerateObjectsUsingBlock:^(NSString * _Nonnull mean, NSUInteger idx, BOOL * _Nonnull stop) {
            EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
            wordButton.fontSize = 14 * self.fontSizeRatio;
            [wordButton setTitle:mean];
            [wrapView addSubview:wordButton];
            [wordButton setClickBlock:^(EZButton *_Nonnull button) {
                mm_strongify(self);
                if (self.queryTextBlock) {
                    self.queryTextBlock(mean);
                }
                [mean copyToPasteboard];
            }];
        }];
        
        [partLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(kHorizontalMargin_8);
            make.centerY.equalTo(wrapView.subviews.firstObject);
            CGSize labelSize = [partLabel oneLineSize];
            make.size.mas_equalTo(labelSize).priorityHigh();
        }];
        
        [wrapView mas_makeConstraints:^(MASConstraintMaker *make) {
            CGFloat topOffset = kBlueTextButtonVerticalPadding_2;
            make.top.equalTo(rtnView.mas_bottom).offset(topOffset);
            *height += topOffset;
            make.left.equalTo(partLabel.mas_right);
            make.right.equalTo(self);
        }];
        
        [wrapView layoutSubtreeIfNeeded];
        CGSize wrapViewSize = [wrapView intrinsicContentSize];
        *height += wrapViewSize.height;
        rtnView = wrapView;
    }];
    
    return rtnView;
}

- (void)updateTagButton:(NSButton *)tagButton tagColor:(NSColor *)tagColor {
    tagButton.wantsLayer = YES;
    tagButton.layer.borderWidth = 1.2;
    tagButton.layer.cornerRadius = 3;
    tagButton.layer.borderColor = tagColor.CGColor;
    tagButton.bordered = NO;
    
    NSAttributedString *attributedString = [NSAttributedString mm_attributedStringWithString:tagButton.title font:[NSFont systemFontOfSize:12 * self.fontSizeRatio] color:tagColor];
    tagButton.attributedTitle = attributedString;
}

- (CGSize)labelSize:(EZLabel *)label exceptedWidth:(CGFloat)exceptedWidth {
    // ???: 很奇怪，比如实际计算结果为 364，但界面渲染却是 364.5 😑
    CGFloat width = self.width - exceptedWidth;
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

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webView didFinishNavigation");

    [self.result.webViewManager updateAllIframe];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailNavigation: %@", error);
}

/** 请求服务器发生错误 (如果是goBack时，当前页面也会回调这个方法，原因是NSURLErrorCancelled取消加载) */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailProvisionalNavigation: %@", error);
}

// 监听 JavaScript 代码是否执行
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // JavaScript 代码执行
    NSLog(@"runJavaScriptAlertPanelWithMessage: %@", message);
}


/** 在收到响应后，决定是否跳转 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    //    NSLog(@"decidePolicyForNavigationResponse: %@", navigationResponse.response.URL.absoluteString);
    
    // 这里可以查看页面内部的网络请求，并做出相应的处理
    // navigationResponse 包含了请求的相关信息，你可以通过它来获取请求的 URL、请求方法、请求头等信息
    // decisionHandler 是一个回调，你可以通过它来决定是否允许这个请求发送
    
    
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
    //不允许跳转
    // decisionHandler(WKNavigationResponsePolicyCancel);
}

/** 接收到服务器跳转请求即服务重定向时之后调用 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    //    NSLog(@"didReceiveServerRedirectForProvisionalNavigation: %@", webView.URL.absoluteURL);
}

/** 收到服务器响应后，在发送请求之前，决定是否跳转 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *navigationActionURL = navigationAction.request.URL;
    //    NSLog(@"decidePolicyForNavigationAction URL: %@", navigationActionURL);
    
    /**
     If URL has a prefix "x-dictionary", means this is a Apple Dictionary URI scheme. Docs: https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/DictionaryServicesProgGuide/schema/schema.html
     
     x-dictionary:r:m_en_gbus0793530:com.apple.dictionary.NOAD:poikilotherm
     x-dictionary:r:z_DWS-004175:com.apple.dictionary.zh_CN-en.OCD
     */
    if ([navigationActionURL.scheme isEqualToString:kAppleDictionaryURIScheme]) {
        NSLog(@"Open URI: %@", navigationActionURL);
        
        NSString *hrefText = [navigationActionURL.absoluteString decode];
        
        [self getTextWithHref:hrefText completionHandler:^(NSString *text) {
            NSLog(@"URL text is: %@", text);
            
            if (self.queryTextBlock) {
                self.queryTextBlock([text trim]);
            }
        }];
        
        //        [[NSWorkspace sharedWorkspace] openURL:navigationActionURL];
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
    //不允许跳转
    // decisionHandler(WKNavigationActionPolicyCancel);
}

#pragma mark -

- (void)updateWebViewHeight:(CGFloat)scrollHeight {
    // Cost ~0.15s
    //    NSString *script = @"document.documentElement.scrollHeight;";
    
    NSLog(@"scrollHeight: %.1f", scrollHeight);
    
    CGFloat visibleFrameHeight = EZLayoutManager.shared.screen.visibleFrame.size.height;
    CGFloat maxHeight = visibleFrameHeight * 0.55;
    
    EZBaseQueryWindow *floatingWindow = EZWindowManager.shared.floatingWindow;
    EZBaseQueryViewController *queryViewController = floatingWindow.queryViewController;
    if (queryViewController.services.count == 1) {
        maxHeight = visibleFrameHeight - floatingWindow.height - self.bottomViewHeight;
    }
    
    // Fix strange white line
    CGFloat webViewHeight = ceil(MIN(maxHeight, scrollHeight));
    CGFloat viewHeight = self.bottomViewHeight + webViewHeight;
    
    /**
     Improve scrollable height:
     
     If contentHeight > maxHeight, we shoud show scrollbar temporarily.
     
     TODO: if contentHeight <= maxHeight, we should disable webView scroll but enable tableView scroll.
     */
    NSMutableString *jsCode = [NSMutableString string];
    if (scrollHeight > maxHeight) {
        [jsCode appendString:[self jsCodeOfOptimizeScrollableWebView]];
    }
    
    if (jsCode.length) {
        [self evaluateJavaScript:jsCode];
    }
    
    
    [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(webViewHeight);
    }];
    
    
    /**
     If html is too large, it takes a while to render webView, such as run script to adapt to dark mode.
     
     apple: 75747
     take: 1971476
     */
    
    //            CGFloat delayShowingTime = self.result.HTMLString.length / 1000000.0;
    //            NSLog(@"Delay showing time: %.2f", delayShowingTime);
    
    // !!!: Must update view height, then update cell height.
    
    if (self.updateViewHeightBlock) {
        self.updateViewHeightBlock(viewHeight);
    }
    
    
    // Notify tableView to update cell height.
    [queryViewController updateCellWithResult:self.result reloadData:NO];
    
    [self fetchWebViewAllIframeText:^(NSString *text) {
        self.result.copiedText = text;
        
        if (self.didFinishLoadingHTMLBlock) {
            self.didFinishLoadingHTMLBlock();
        }
        
        if (self.result.didFinishLoadingHTMLBlock) {
            self.result.didFinishLoadingHTMLBlock();
        }
    }];
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
    
    return jsCode;
}

- (NSString *)jsCodeOfUpdateBodyTextColor:(NSString *)color backgroundColor:(NSString *)backgroundColor {
    NSString *jsCode = [NSString stringWithFormat:@""
                        @"document.body.style.webkitTextFillColor='%@';"
                        @"document.body.style.backgroundColor='%@';"
                        , color, backgroundColor];
    
    return jsCode;
}

- (NSString *)jsCodeOfUpdateStyleHeight:(CGFloat)height {
    NSString *jsCode = [NSString stringWithFormat:@"document.body.style.height = '%fpx';", height];
    return jsCode;
}

- (NSString *)jsCodeOfOptimizeScrollableWebView {
    NSString *showScrollbarBriefly = @""
    @"window.scrollTo(0, 1);"
    @"setTimeout(function () { window.scrollTo(0, 0); }, 0);";
    
    NSString *jsCode = [NSString stringWithFormat:@"%@", showScrollbarBriefly];
    return jsCode;
}

- (void)evaluateJavaScript:(NSString *)jsCode {
    [self evaluateJavaScript:jsCode completionHandler:nil];
}

- (void)evaluateJavaScript:(NSString *)jsCode completionHandler:(void (^_Nullable)(_Nullable id, NSError *_Nullable error))completionHandler {
    [self.webView evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (error) {
            NSLog(@"error: %@", error);
            NSLog(@"jsCode: %@", jsCode);
        }
        
        if (completionHandler) {
            completionHandler(result, error);
        }
    }];
}

- (void)fetchWebViewAllIframeText:(void (^_Nullable)(NSString *text))completionHandler {
    NSString *jsCode = @""
    "var iframes = document.querySelectorAll('iframe');"
    "var text = '';"
    "for (var i = 0; i < iframes.length; i++) {"
    "   text += iframes[i].contentDocument.body.innerText;"
    "   text += '\\n\\n';"
    "};"
    "text;";
    
    [self evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (!error && [result isKindOfClass:[NSString class]]) {
            if (completionHandler) {
                completionHandler(result);
            }
        }
    }];
}

- (void)getTextWithHref:(NSString *)href completionHandler:(void (^_Nullable)(NSString *text))completionHandler {
    NSString *jsCode = [NSString stringWithFormat:
                        @"var iframes = document.querySelectorAll('iframe');"
                        @"var linkText = '';"
                        @"for (var i = 0; i < iframes.length; i++) {"
                        @"    var iframe = iframes[i];"
                        @"    var linkElement = iframe.contentWindow.document.querySelector('a[href=\"%@\"]');"
                        @"    if (linkElement) {"
                        @"        linkText = linkElement.innerText;"
                        @"        break;"
                        @"    }"
                        @"}"
                        @"linkText;", href];
    
    [self evaluateJavaScript:jsCode completionHandler:^(id result, NSError *error) {
        if (!error) {
            NSString *linkText = (NSString *)result;
            completionHandler(linkText);
        }
    }];
}

- (void)updateWebViewAllIframeFontSize {
    CGFloat fontSize = EZConfiguration.shared.fontSizeRatio * 100;

    NSString *jsCode = [NSString stringWithFormat:
    @"var iframes = document.querySelectorAll('iframe');"
    @"for (var i = 0; i < iframes.length; i++) {"
    @"   var iframe = iframes[i];"
    @"   var frameDoc = iframe.contentDocument || iframe.contentWindow.document;"
    @"   frameDoc.body.style.fontSize = '%f%%';"
    @"};", fontSize];
    
    [self evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (!error) {
            
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
