//
//  EZSelectLanguageCell.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectLanguageCell.h"
#import "EZSelectLanguageButton.h"
#import "EZQueryService.h"
#import "EZGoogleTranslate.h"
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

@property (nonatomic, strong) EZQueryService *translate;
@property (nonatomic, assign) BOOL isTranslating;

@end

@implementation EZSelectLanguageCell


- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.translate = [[EZGoogleTranslate alloc] init];
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
        barView.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#F3F3F3"].CGColor;
    } drak:^(NSView *barView) {
        barView.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#252627"].CGColor;
    }];
    languageBarView.mas_key = @"languageBarView";
    
    
    EZHoverButton *transformButton = [[EZHoverButton alloc] init];
    self.transformButton = transformButton;
    [languageBarView addSubview:transformButton];
    transformButton.toolTip = @"交换语言";
    transformButton.image = [NSImage imageNamed:@"transform"];
    
    [transformButton excuteLight:^(id _Nonnull x) {
        transformButton.contentTintColor = NSColor.blackColor;
    } drak:^(id _Nonnull x) {
        transformButton.contentTintColor = NSColor.whiteColor;
    }];
    
    mm_weakify(self);
    [self.transformButton setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        
        EZLanguage fromLang = EZConfiguration.shared.from;
        EZLanguage toLang = EZConfiguration.shared.to;
        
        EZConfiguration.shared.from = toLang;
        EZConfiguration.shared.to = fromLang;
        
        [self.fromLanguageButton setSelectedLanguage:toLang];
        [self.fromLanguageButton setSelectedLanguage:fromLang];
        
        [self enterAction];
    }];
    transformButton.mas_key = @"transformButton";
    
    self.fromLanguageButton = [EZSelectLanguageButton mm_make:^(EZSelectLanguageButton *_Nonnull button) {
        [languageBarView addSubview:button];
        // Just resolve layout warning.
        button.frame = self.bounds;
        
        EZLanguage from = EZConfiguration.shared.from;
        [button setSelectedLanguage:from];
        
        mm_weakify(self);
        [button setSelectedMenuItemBlock:^(EZLanguage  _Nonnull selectedLanguage) {
            mm_strongify(self);
            self.queryModel.userSourceLanguage = selectedLanguage;
            
            if (![selectedLanguage isEqualToString:from]) {
                EZConfiguration.shared.from = selectedLanguage;
                [self enterAction];
            }
        }];
    }];
    self.fromLanguageButton.mas_key = @"fromLanguageButton";
    
    self.toLanguageButton = [EZSelectLanguageButton mm_make:^(EZSelectLanguageButton *_Nonnull button) {
        [languageBarView addSubview:button];
        button.frame = self.bounds;
        button.autoChineseSelectedTitle = @"自动选择";
        
        EZLanguage toLang = EZConfiguration.shared.to;
        [button setSelectedLanguage:toLang];
        
        mm_weakify(self);
        [button setSelectedMenuItemBlock:^(EZLanguage  _Nonnull selectedLanguage) {
            mm_strongify(self);
            
            self.queryModel.userTargetLanguage = selectedLanguage;
            
            if (![selectedLanguage isEqualToString:toLang]) {
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
    
    CGFloat languageButtonWidth = 90;
    CGFloat transformButtonWidth = 25;
    
    [self.transformButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.languageBarView);
        make.width.height.mas_equalTo(transformButtonWidth);
    }];
    
    CGFloat padding = ((self.width - transformButtonWidth) / 2 - languageButtonWidth) / 2;
    
    // Shift a bit to the left so that the UI looks better.
    padding -= 10;
    
    //    NSLog(@"query cell padding: %.1f", padding);
    
    [self.fromLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.languageBarView);
        make.height.mas_equalTo(transformButtonWidth);
        make.left.equalTo(self.languageBarView).offset(padding);
    }];
    
    [self.toLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.width.height.equalTo(self.fromLanguageButton);
        make.right.equalTo(self.languageBarView).offset(-padding);
    }];
    
    [super updateConstraints];
}

- (void)setQueryModel:(EZQueryModel *)queryModel {
    _queryModel = queryModel;
    
    if ([queryModel.userSourceLanguage isEqualToString:EZLanguageAuto]) {
        self.fromLanguageButton.autoSelectedLanguage = queryModel.queryFromLanguage;
    }
    if ([queryModel.userTargetLanguage isEqualToString:EZLanguageAuto]) {
        self.toLanguageButton.autoSelectedLanguage = queryModel.queryTargetLanguage;
    }
}

- (void)enterAction {
    NSLog(@"enterAction");
    
    if (self.enterActionBlock) {
        self.enterActionBlock(EZConfiguration.shared.from, EZConfiguration.shared.to);
    }
}

- (void)dealloc {
    //    NSLog(@"dealloc: %@", self);
}

@end
