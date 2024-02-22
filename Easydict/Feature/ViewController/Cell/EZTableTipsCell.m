//
//  EZTableTipsCell.m
//  Easydict
//
//  Created by Sharker on 2024/2/18.
//  Copyright © 2024 izual. All rights reserved.
//

#import "EZTableTipsCell.h"
#import "EZOpenLinkButton.h"
#import "NSImage+EZSymbolmage.h"
#import "EZLanguageManager.h"

@interface EZTableTipsCell()
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSImageView *tipsIconImageView;
@property (nonatomic, strong) NSTextField *tipsNameLabel;
@property (nonatomic, strong) NSTextField *tipsContentLabel;
@property (nonatomic, strong) EZOpenLinkButton *moreBtn;
@property (nonatomic, strong) EZOpenLinkButton *solveBtn;
@property (nonatomic, strong) NSDictionary *dataDict;
@property (nonatomic, strong) NSString *questionSolveURL;
@property (nonatomic, strong) NSString *seeMoreURL;
@end

@implementation EZTableTipsCell

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self updateQuestionContent];
    }
    return self;
}

- (void)setupUI {
    // mas key
    self.contentView.mas_key = @"topBarView";
    self.tipsIconImageView.mas_key = @"tipsIconImageView";
    self.tipsNameLabel.mas_key = @"tipsNameLabel";
    self.moreBtn.mas_key = @"moreBtn";
    self.solveBtn.mas_key = @"solveBtn";
    
    CGSize iconSize = CGSizeMake(20, 20);
    CGSize buttonSize = CGSizeMake(94, 32);
    
    // constraints
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    [self.tipsIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.top.mas_equalTo(9);
        make.size.mas_equalTo(iconSize);
    }];
    
    [self.tipsNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.tipsIconImageView.mas_right).offset(6);
        make.centerY.mas_equalTo(self.tipsIconImageView.mas_centerY).offset(1);
    }];
    
//    [self.tipsContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.mas_equalTo(9);
//        make.width.mas_lessThanOrEqualTo(self.bounds.size.width - 9);
//        make.top.mas_equalTo(self.tipsNameLabel.mas_bottom).offset(12);
//    }];
    
    [self.solveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.top.mas_equalTo(self.tipsContentLabel.mas_bottom).offset(9);
        make.size.mas_equalTo(buttonSize);
    }];
    
    [self.moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.solveBtn.mas_right).offset(20);
        make.top.mas_equalTo(self.solveBtn);
        make.size.mas_equalTo(buttonSize);
    }];
}

- (void)updateConstraints {
    
    [self.tipsContentLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.width.mas_lessThanOrEqualTo(self.bounds.size.width - 9);
        make.top.mas_equalTo(self.tipsNameLabel.mas_bottom).offset(12);
    }];
    
    [super updateConstraints];
}

- (void)updateQuestionContent {
    NSArray *questions = self.dataDict[@"questions"];
    int index = arc4random() % questions.count;
    self.tipsContentLabel.stringValue = questions[index];
    NSArray *solves;
    if ([[EZLanguageManager shared].ezCurrentLanguage isEqualToString:@"CNY"]) {
        solves = self.dataDict[@"solveZh"];
    } else {
        solves = self.dataDict[@"solveEn"];
    }
    self.questionSolveURL = solves[index];
    self.solveBtn.link = self.questionSolveURL;
}

- (CGFloat)cellHeight {
    CGFloat cellHeight = 9 + 20 + 12 + self.tipsContentLabel.height + 9 + 32 + 6;
    return cellHeight;
}

#pragma mark - Accesstor
- (NSView *)contentView {
    if (!_contentView) {
        mm_weakify(self);
        _contentView = [NSView mm_make:^(NSView *_Nonnull view) {
            mm_strongify(self);
            [self addSubview:view];
            view.wantsLayer = YES;
            view.layer.cornerRadius = EZCornerRadius_8;
            [view.layer excuteLight:^(CALayer *layer) {
                layer.backgroundColor = [NSColor ez_titleBarBgLightColor].CGColor;
            } dark:^(CALayer *layer) {
                layer.backgroundColor = [NSColor ez_titleBarBgDarkColor].CGColor;
            }];
        }];
    }
    return _contentView;
}

- (NSImageView *)tipsIconImageView {
    if (!_tipsIconImageView) {
        mm_weakify(self);
        _tipsIconImageView = [NSImageView mm_make:^(NSImageView *imageView) {
            mm_strongify(self);
            [self.contentView addSubview:imageView];
            [imageView setImage:[NSImage imageNamed:@"tip_Normal"]];
        }];
    }
    return _tipsIconImageView;
}

- (NSTextField *)tipsNameLabel {
    if (!_tipsNameLabel) {
        mm_weakify(self);
        _tipsNameLabel = [NSTextField mm_make:^(NSTextField *label) {
            mm_strongify(self);
            [self.contentView addSubview:label];
            label.stringValue = NSLocalizedString(@"tips_title", nil);
            label.editable = NO;
            label.bordered = NO;
            label.backgroundColor = NSColor.clearColor;
            label.alignment = NSTextAlignmentCenter;
            label.font = [NSFont systemFontOfSize:14];
            [label excuteLight:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextLightColor];
            } dark:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextDarkColor];
            }];
        }];
    }
    return _tipsNameLabel;
}

- (NSTextField *)tipsContentLabel {
    if (!_tipsContentLabel) {
        mm_weakify(self);
        _tipsContentLabel = [NSTextField mm_make:^(NSTextField *label) {
            mm_strongify(self);
            [self.contentView addSubview:label];
            label.editable = NO;
            label.bordered = NO;
            label.backgroundColor = NSColor.clearColor;
            label.alignment = NSTextAlignmentLeft;
            label.stringValue = self.dataDict[@"questions"][0];
            label.usesSingleLineMode = NO;
            label.maximumNumberOfLines = 0;
            [label excuteLight:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextLightColor];
            } dark:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextDarkColor];
            }];
        }];
    }
    return _tipsContentLabel;
}

- (EZOpenLinkButton *)moreBtn {
    if (!_moreBtn) {
        _moreBtn = [[EZOpenLinkButton alloc] init];
        [self addSubview:_moreBtn];
        NSImage *moreBtnImage = [NSImage ez_imageWithSymbolName:@"ellipsis.circle.fill"];
        _moreBtn.image = moreBtnImage;
        _moreBtn.title = NSLocalizedString(@"tips_more", nil);
        _moreBtn.imagePosition = NSImageLeft;
        _moreBtn.edgeInsets = NSEdgeInsetsMake(0, 3, 0, 3);
        [_moreBtn excuteLight:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
        } dark:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
        }];
        _moreBtn.link = self.seeMoreURL;
    }
    return _moreBtn;
}

- (EZOpenLinkButton *)solveBtn {
    if (!_solveBtn) {
        _solveBtn = [[EZOpenLinkButton alloc] init];
        [self addSubview:_solveBtn];
        NSImage *solveBtnImage = [NSImage ez_imageWithSymbolName:@"link.circle.fill"];
        _solveBtn.image = solveBtnImage;
        _solveBtn.imagePosition = NSImageLeft;
        _solveBtn.title = NSLocalizedString(@"tips_solve", nil);
        _solveBtn.edgeInsets = NSEdgeInsetsMake(0, 3, 0, 3);
        [_solveBtn excuteLight:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
        } dark:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
        }];
    }
    return _solveBtn;
}

- (NSDictionary *)dataDict {
    if (!_dataDict) {
        _dataDict = @{
            @"questions":@[
                NSLocalizedString(@"tips_text_empty", nil),
                NSLocalizedString(@"tips_mouse_hover", nil),
                NSLocalizedString(@"tips_beep", nil),
                NSLocalizedString(@"tips_edit_button", nil),
                NSLocalizedString(@"tips_might_selecting", nil),
                NSLocalizedString(@"tips_word_selection_OCR", nil),
                NSLocalizedString(@"tips_select_words", nil),
                NSLocalizedString(@"tips_still_pop_up", nil),
            ],
            @"solveEn":@[
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-is-the-text-empty-when-i-select-words-in-some-applications",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-cant-i-use-mouse-hover-to-select-words-in-some-applications",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-is-there-a-beep-when-the-selected-word-is-empty-such-as-dragging-in-a-blank-area-in-some-applications",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-does-the-edit-button-in-the-upper-right-corner-flicker-when-selecting-words-in-some-applications",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-might-selecting-an-empty-word-interrupt-the-music-currently-playing",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-do-word-selection-and-ocr-need-to-enable-system-related-permissions",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-cant-i-select-words-on-some-web-pages-in-the-browser",
                @"https://github.com/tisfeng/Easydict/wiki/FAQ#why-does-macos-still-pop-up-asking-for-permissions-even-though-i-have-given-easydict-the-accessibilityscreen-recording-permissions"
            ],
            @"solveZh":@[
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%9C%A8%E6%9F%90%E4%BA%9B%E5%BA%94%E7%94%A8%E4%B8%AD%E5%8F%96%E8%AF%8D%E6%96%87%E6%9C%AC%E4%B8%BA%E7%A9%BA",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%9C%A8%E6%9F%90%E4%BA%9B%E5%BA%94%E7%94%A8%E4%B8%AD%E6%97%A0%E6%B3%95%E4%BD%BF%E7%94%A8%E9%BC%A0%E6%A0%87%E5%88%92%E8%AF%8D",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%9C%A8%E6%9F%90%E4%BA%9B%E5%BA%94%E7%94%A8%E5%8F%96%E8%AF%8D%E4%B8%BA%E7%A9%BA%E7%A9%BA%E7%99%BD%E5%A4%84%E6%8B%96%E5%8A%A8%E7%AD%89%E6%97%B6%E4%BC%9A%E5%87%BA%E7%8E%B0%E6%8F%90%E7%A4%BA%E9%9F%B3",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%9C%A8%E6%9F%90%E4%BA%9B%E5%BA%94%E7%94%A8%E5%8F%96%E8%AF%8D%E6%97%B6%E5%8F%B3%E4%B8%8A%E8%A7%92%E7%BC%96%E8%BE%91%E6%8C%89%E9%92%AE%E4%BC%9A%E5%87%BA%E7%8E%B0%E9%97%AA%E7%83%81",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%8F%96%E8%AF%8D%E4%B8%BA%E7%A9%BA%E6%97%B6%E5%8F%AF%E8%83%BD%E6%89%93%E6%96%AD%E5%BD%93%E5%89%8D%E6%92%AD%E6%94%BE%E7%9A%84%E9%9F%B3%E4%B9%90",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E5%8F%96%E8%AF%8D%E5%92%8C-ocr-%E9%9C%80%E8%A6%81%E5%BC%80%E5%90%AF%E7%B3%BB%E7%BB%9F%E7%9B%B8%E5%85%B3%E6%9D%83%E9%99%90",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E4%B8%BA%E4%BB%80%E4%B9%88%E6%B5%8F%E8%A7%88%E5%99%A8%E4%B8%AD%E6%9F%90%E4%BA%9B%E7%BD%91%E9%A1%B5%E6%97%A0%E6%B3%95%E5%8F%96%E8%AF%8D",
                @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98#%E5%B7%B2%E7%BB%8F%E7%BB%99-easydict-%E8%BE%85%E5%8A%A9%E5%8A%9F%E8%83%BD%E5%BD%95%E5%B1%8F%E6%9D%83%E9%99%90-macos-%E4%BB%8D%E7%84%B6%E5%BC%B9%E7%AA%97%E8%A6%81%E6%B1%82%E7%BB%99%E4%BA%88%E6%9D%83%E9%99%90"
            ],
        };
    }
    return _dataDict;
}

- (NSString *)seeMoreURL {
    if (!_seeMoreURL) {
        NSString *languageCode = [[EZLanguageManager shared] ezCurrentLanguage];
        if ([languageCode isEqualToString:@"CNY"]) {
            _seeMoreURL = @"https://github.com/tisfeng/Easydict/wiki/%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98";
        } else {
            _seeMoreURL = @"https://github.com/tisfeng/Easydict/wiki/FAQ";
        }
    }
    return _seeMoreURL;
}
@end
