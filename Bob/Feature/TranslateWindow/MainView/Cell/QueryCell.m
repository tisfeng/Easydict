//
//  QueryCell.m
//  Bob
//
//  Created by tisfeng on 2022/11/4.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "QueryCell.h"
#import "PopUpButton.h"
#import "TranslateService.h"
#import "GoogleTranslate.h"
#import "Configuration.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"

static const CGFloat kVerticalMargin = 10;

@interface QueryCell ()

@property (nonatomic, strong) PopUpButton *fromLanguageButton;
@property (nonatomic, strong) NSButton *transformButton;
@property (nonatomic, strong) PopUpButton *toLanguageButton;
@property (nonatomic, strong) TranslateService *translate;
@property (nonatomic, assign) BOOL isTranslating;


@end

@implementation QueryCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.translate = [[GoogleTranslate alloc] init];
        [self setup];
    }
    return  self;
}

- (void)setup {
    EZQueryView *inputView = [[EZQueryView alloc] initWithFrame:self.bounds];
    self.queryView = inputView;
    [self addSubview:inputView];
    [inputView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(90);
    }];
    
    NSView *selectLanguageBarView = [[NSView alloc] init];
    [self addSubview:selectLanguageBarView];
    selectLanguageBarView.wantsLayer = YES;
    selectLanguageBarView.layer.cornerRadius = 8;
    [selectLanguageBarView excuteLight:^(NSView *barView) {
        barView.layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
    } drak:^(NSView *barView) {
        barView.layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
    }];
    
    [selectLanguageBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.queryView.mas_bottom).offset(kVerticalMargin);
        make.left.right.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(35);
        make.bottom.equalTo(self);
    }];
    
    CGFloat transformButtonWidth = 20;
    EZHoverButton *transformButton = [[EZHoverButton alloc] init];
    self.transformButton = transformButton;
    [selectLanguageBarView addSubview:transformButton];
    transformButton.bordered = NO;
    transformButton.toolTip = @"交换语言";
    transformButton.imageScaling = NSImageScaleProportionallyDown;
    transformButton.bezelStyle = NSBezelStyleRegularSquare;
    [transformButton setButtonType:NSButtonTypeMomentaryChange];
    transformButton.image = [NSImage imageNamed:@"transform"];
    
    [transformButton excuteLight:^(id _Nonnull x) {
        transformButton.contentTintColor = NSColor.blackColor;
    } drak:^(id _Nonnull x) {
        transformButton.contentTintColor = NSColor.whiteColor;
    }];
    
    [transformButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(selectLanguageBarView);
        make.width.height.mas_equalTo(transformButtonWidth);
    }];
    
    mm_weakify(self);
    [transformButton setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self)
        Language from = Configuration.shared.from;
        Configuration.shared.from = Configuration.shared.to;
        Configuration.shared.to = from;
        [self.fromLanguageButton updateWithIndex:[self.translate indexForLanguage:Configuration.shared.from]];
        [self.toLanguageButton updateWithIndex:[self.translate indexForLanguage:Configuration.shared.to]];
        
        [self enterAction];
    }];
    
    CGFloat languageButtonWidth = 90;
    CGFloat padding = ((self.width - transformButtonWidth) / 2 - languageButtonWidth) / 2;
    
    self.fromLanguageButton = [PopUpButton mm_make:^(PopUpButton *_Nonnull button) {
        [selectLanguageBarView addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(selectLanguageBarView);
            make.height.mas_equalTo(25);
            make.left.equalTo(self).offset(padding);
        }];
        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj integerValue] == Language_auto) {
                return @"自动检测";
            }
            return LanguageDescFromEnum([obj integerValue]);
        }]];
        [button updateWithIndex:[self.translate indexForLanguage:Configuration.shared.from]];
        mm_weakify(self);
        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
            mm_strongify(self);
            NSInteger from = [[self.translate.languages objectAtIndex:index] integerValue];
            NSLog(@"from 选中语言 %zd %@", from, LanguageDescFromEnum(from));
            if (from != Configuration.shared.from) {
                Configuration.shared.from = from;
                [self enterAction];
            }
        }];
    }];
    
    
    self.toLanguageButton = [PopUpButton mm_make:^(PopUpButton *_Nonnull button) {
        [selectLanguageBarView addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.fromLanguageButton);
            make.width.height.equalTo(self.fromLanguageButton);
            
            make.right.equalTo(self).offset(-padding);
        }];
        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj integerValue] == Language_auto) {
                return @"自动选择";
            }
            return LanguageDescFromEnum([obj integerValue]);
        }]];
        [button updateWithIndex:[self.translate indexForLanguage:Configuration.shared.to]];
        mm_weakify(self);
        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
            mm_strongify(self);
            NSInteger to = [[self.translate.languages objectAtIndex:index] integerValue];
            NSLog(@"to 选中语言 %zd %@", to, LanguageDescFromEnum(to));
            if (to != Configuration.shared.to) {
                Configuration.shared.to = to;
                [self enterAction];
            }
        }];
    }];
}

- (void)enterAction {
    if (self.enterActionBlock) {
        self.enterActionBlock(self.queryView.copiedText);
    }
}


- (void)setEnterActionBlock:(void (^)(NSString * _Nonnull))enterActionBlock {
    _enterActionBlock = enterActionBlock;
    
    self.queryView.enterActionBlock = enterActionBlock;
}

- (void)setAudioActionBlock:(void (^)(NSString * _Nonnull))audioActionBlock {
    _audioActionBlock = audioActionBlock;
    
    self.queryView.playAudioBlock = audioActionBlock;
}

- (void)setCopyActionBlock:(void (^)(NSString * _Nonnull))copyActionBlock {
    _copyActionBlock = copyActionBlock;
    
    self.queryView.copyActionBlock = copyActionBlock;
}

@end
