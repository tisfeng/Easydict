//
//  EZSelectLanguageCell.m
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectLanguageCell.h"
#import "EZSelectLanguageButton.h"
#import "EZConfiguration.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"

@interface EZSelectLanguageCell ()

@property (nonatomic, strong) NSView *languageBarView;

@property (nonatomic, strong) EZSelectLanguageButton *fromLanguageButton;
@property (nonatomic, copy) EZLanguage fromLanguage;

@property (nonatomic, strong) EZHoverButton *transformButton;

@property (nonatomic, strong) EZSelectLanguageButton *toLanguageButton;
@property (nonatomic, copy) EZLanguage toLanguage;

@property (nonatomic, assign) BOOL isTranslating;

@end

@implementation EZSelectLanguageCell


- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return  self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.cornerRadius = EZCornerRadius_8;
    
    NSView *languageBarView = [[NSView alloc] initWithFrame:self.bounds];
    [self addSubview:languageBarView];
    self.languageBarView = languageBarView;
    languageBarView.wantsLayer = YES;
    languageBarView.layer.cornerRadius = EZCornerRadius_8;
    [languageBarView excuteLight:^(NSView *barView) {
        barView.layer.backgroundColor = [NSColor titleBarBgLightColor].CGColor;
    } dark:^(NSView *barView) {
        barView.layer.backgroundColor = [NSColor titleBarBgDarkColor].CGColor;

    }];
    languageBarView.mas_key = @"languageBarView";
    
    
    EZHoverButton *transformButton = [[EZHoverButton alloc] init];
    self.transformButton = transformButton;
    [languageBarView addSubview:transformButton];
    transformButton.toolTip = @"Toggle Languages, ⌘+T";
    transformButton.image = [NSImage imageNamed:@"transform"];
    
    [transformButton excuteLight:^(EZHoverButton *transformButton) {
        transformButton.contentTintColor = NSColor.blackColor;
    } dark:^(EZHoverButton *transformButton) {
        transformButton.contentTintColor = NSColor.whiteColor;
    }];
    
    mm_weakify(self);
    [self.transformButton setClickBlock:^(EZButton *button) {
        mm_strongify(self);
        [self toggleTranslationLanguages];
    }];
    transformButton.mas_key = @"transformButton";
    
    self.fromLanguageButton = [EZSelectLanguageButton mm_make:^(EZSelectLanguageButton *_Nonnull button) {
        [languageBarView addSubview:button];
        
        mm_weakify(self);
        [button setSelectedMenuItemBlock:^(EZLanguage selectedLanguage) {
            mm_strongify(self);
            self.queryModel.userSourceLanguage = selectedLanguage;
            
            if (![selectedLanguage isEqualToString:EZConfiguration.shared.from]) {
                EZConfiguration.shared.from = selectedLanguage;
                [self enterAction];
            }
        }];
    }];
    self.fromLanguageButton.mas_key = @"fromLanguageButton";
    
    self.toLanguageButton = [EZSelectLanguageButton mm_make:^(EZSelectLanguageButton *_Nonnull button) {
        [languageBarView addSubview:button];
        button.autoChineseSelectedTitle = @"自动选择";

        mm_weakify(self);
        [button setSelectedMenuItemBlock:^(EZLanguage selectedLanguage) {
            mm_strongify(self);
            self.queryModel.userTargetLanguage = selectedLanguage;
            
            if (![selectedLanguage isEqualToString:EZConfiguration.shared.to]) {
                EZConfiguration.shared.to = selectedLanguage;
                [self enterAction];
            }
        }];
    }];
    self.toLanguageButton.mas_key = @"toLanguageButton";
}

- (void)updateConstraints {
    [self.languageBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    CGFloat transformButtonWidth = 26;
    [self.transformButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.languageBarView);
        make.width.height.mas_equalTo(transformButtonWidth);
    }];
    
    
    CGFloat halfWidth = (self.width - transformButtonWidth) / 2;
    CGFloat fromButtonMargin = (halfWidth - self.fromLanguageButton.buttonWidth) / 2;
    fromButtonMargin = MAX(fromButtonMargin, 0);
    CGFloat toButtonMargin = (halfWidth - self.toLanguageButton.buttonWidth) / 2;
    toButtonMargin = MAX(toButtonMargin, 0);

    [self.fromLanguageButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.languageBarView);
        make.height.mas_equalTo(transformButtonWidth);
        make.right.lessThanOrEqualTo(self.transformButton.mas_left).offset(-fromButtonMargin);
    }];
    
    [self.toLanguageButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.languageBarView);
        make.height.mas_equalTo(transformButtonWidth);
        make.left.greaterThanOrEqualTo(self.transformButton.mas_right).offset(toButtonMargin);
    }];
    
    [super updateConstraints];
}

- (void)setQueryModel:(EZQueryModel *)queryModel {
    _queryModel = queryModel;
    
    self.fromLanguageButton.selectedLanguage = queryModel.userSourceLanguage;
    if ([queryModel.userSourceLanguage isEqualToString:EZLanguageAuto]) {
        self.fromLanguageButton.autoSelectedLanguage = queryModel.queryFromLanguage;
    }
    
    self.toLanguageButton.selectedLanguage = queryModel.userTargetLanguage;
    if ([queryModel.userTargetLanguage isEqualToString:EZLanguageAuto]) {
        self.toLanguageButton.autoSelectedLanguage = queryModel.queryTargetLanguage;
    }
}

- (void)toggleTranslationLanguages {
    EZLanguage fromLang = self.queryModel.userSourceLanguage;
    EZLanguage toLang = self.queryModel.userTargetLanguage;
    
    if (![fromLang isEqualToString:toLang]) {
        EZConfiguration.shared.from = toLang;
        EZConfiguration.shared.to = fromLang;
        
        [self.fromLanguageButton setSelectedLanguage:toLang];
        [self.toLanguageButton setSelectedLanguage:fromLang];
        
        [self enterAction];
    }
}

// TODO: need to optimize. This should not use EZConfiguration directly.
- (void)enterAction {
    NSLog(@"enterAction");
    
    [self setNeedsUpdateConstraints:YES];
    
    if (self.enterActionBlock) {
        self.enterActionBlock(EZConfiguration.shared.from, EZConfiguration.shared.to);
    }
}

- (void)dealloc {
    //    NSLog(@"dealloc: %@", self);
}

@end
