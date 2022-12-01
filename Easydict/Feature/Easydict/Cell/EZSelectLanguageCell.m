//
//  EZSelectLanguageCell.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectLanguageCell.h"
#import "EZPopUpButton.h"
#import "EZQueryService.h"
#import "EZGoogleTranslate.h"
#import "EZConfiguration.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"

@interface EZSelectLanguageCell ()

@property (nonatomic, strong) NSView *languageBarView;

@property (nonatomic, strong) EZPopUpButton *fromLanguageButton;
@property (nonatomic, strong) NSButton *transformButton;
@property (nonatomic, strong) EZPopUpButton *toLanguageButton;
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
    [transformButton setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        EZLanguage from = EZConfiguration.shared.from;
        EZConfiguration.shared.from = EZConfiguration.shared.to;
        EZConfiguration.shared.to = from;
        [self.fromLanguageButton updateWithIndex:[self.translate indexForLanguage:EZConfiguration.shared.from]];
        [self.toLanguageButton updateWithIndex:[self.translate indexForLanguage:EZConfiguration.shared.to]];
        
        [self enterAction];
    }];
    transformButton.mas_key = @"transformButton";
    
    self.fromLanguageButton = [EZPopUpButton mm_make:^(EZPopUpButton *_Nonnull button) {
        [languageBarView addSubview:button];
        // Only resolve layout warning.
        button.frame = self.bounds;
        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj isEqualToString:EZLanguageAuto]) {
                return @"自动检测";
            }
            return obj;
        }]];
        [button updateWithIndex:[self.translate indexForLanguage:EZConfiguration.shared.from]];
        mm_weakify(self);
        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
            mm_strongify(self);
            EZLanguage from = [self.translate.languages objectAtIndex:index];
            NSLog(@"from 选中语言: %@", from);
            if ([from isEqualToString: EZConfiguration.shared.from]) {
                EZConfiguration.shared.from = from;
                [self enterAction];
            }
        }];
    }];
    self.fromLanguageButton.mas_key = @"fromLanguageButton";
    
    
    self.toLanguageButton = [EZPopUpButton mm_make:^(EZPopUpButton *_Nonnull button) {
        [languageBarView addSubview:button];
        button.frame = self.bounds;
        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj isEqualToString: EZLanguageAuto]) {
                return @"自动选择";
            }
            return obj;
        }]];
        [button updateWithIndex:[self.translate indexForLanguage:EZConfiguration.shared.to]];
        mm_weakify(self);
        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
            mm_strongify(self);
            EZLanguage to = [self.translate.languages objectAtIndex:index];
            NSLog(@"to 选中语言: %@", to);
            if (![to isEqualToString: EZConfiguration.shared.to]) {
                EZConfiguration.shared.to = to;
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
    //    NSLog(@"query cell padding: %.1f", padding);
    
    [self.fromLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.languageBarView);
        make.height.mas_equalTo(25);
        make.left.equalTo(self.languageBarView).offset(padding);
    }];
    
    [self.toLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.width.height.equalTo(self.fromLanguageButton);
        make.right.equalTo(self.languageBarView).offset(-padding);
    }];
    
    [super updateConstraints];
}

- (void)enterAction {
    NSLog(@"enterAction");
}


#pragma mark - Setter

- (void)setEnterActionBlock:(void (^)(NSString * _Nonnull))enterActionBlock {
    _enterActionBlock = enterActionBlock;
}


- (void)dealloc {
    NSLog(@"dealloc: %@", self);
}

@end
