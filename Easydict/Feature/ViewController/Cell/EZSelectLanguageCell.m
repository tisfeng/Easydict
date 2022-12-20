//
//  EZSelectLanguageCell.m
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectLanguageCell.h"
#import "EZSelectLanguageButton.h"
#import "EZQueryService.h"
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
    
    CGFloat transformButtonWidth = 26;
    [self.transformButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.languageBarView);
        make.width.height.mas_equalTo(transformButtonWidth);
    }];
    
    
    CGFloat halfWidth = (self.width - transformButtonWidth) / 2;
    CGFloat fromButtonMargin = (halfWidth - self.fromLanguageButton.buttonWidth) / 2;
    CGFloat toButtonMargin = (halfWidth - self.toLanguageButton.buttonWidth) / 2;

    [self.fromLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.languageBarView);
        make.height.mas_equalTo(transformButtonWidth);
        make.left.greaterThanOrEqualTo(self.languageBarView).offset(fromButtonMargin);
//        make.right.lessThanOrEqualTo(self.transformButton.mas_left).offset(-3).priorityLow();
    }];
    
    [self.toLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.languageBarView);
        make.height.mas_equalTo(transformButtonWidth);
        make.right.lessThanOrEqualTo(self.languageBarView).offset(-toButtonMargin);
//        make.left.greaterThanOrEqualTo(self.transformButton.mas_right).offset(3);
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
