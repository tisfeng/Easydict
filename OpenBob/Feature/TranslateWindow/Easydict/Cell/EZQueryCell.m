//
//  QueryCell.m
//  Bob
//
//  Created by tisfeng on 2022/11/4.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZQueryCell.h"
#import "PopUpButton.h"
#import "TranslateService.h"
#import "GoogleTranslate.h"
#import "Configuration.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"
#import "EZConst.h"

@interface EZQueryCell ()

@property (nonatomic, strong) NSView *languageBarView;

@property (nonatomic, strong) PopUpButton *fromLanguageButton;
@property (nonatomic, strong) NSButton *transformButton;
@property (nonatomic, strong) PopUpButton *toLanguageButton;
@property (nonatomic, strong) TranslateService *translate;
@property (nonatomic, assign) BOOL isTranslating;

@end

@implementation EZQueryCell


- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.translate = [[GoogleTranslate alloc] init];
        [self setup];
    }
    return  self;
}

- (void)setup {
    EZQueryView *queryView = [[EZQueryView alloc] initWithFrame:self.bounds];
    self.queryView = queryView;
    [self addSubview:queryView];
    
    mm_weakify(self);
    [queryView setUpdateQueryTextBlock:^(NSString * _Nonnull text, CGFloat textViewHeight) {
        mm_strongify(self);
                
        if (self.updateQueryTextBlock) {
            self.updateQueryTextBlock(text, textViewHeight);
        }
    }];
    
//    NSView *languageBarView = [[NSView alloc] init];
//    [self addSubview:languageBarView];
//    self.languageBarView = languageBarView;
//    languageBarView.wantsLayer = YES;
//    languageBarView.layer.cornerRadius = EZCornerRadius_8;
//    [languageBarView excuteLight:^(NSView *barView) {
//        barView.layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
//    } drak:^(NSView *barView) {
//        barView.layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
//    }];
//
//
//    EZHoverButton *transformButton = [[EZHoverButton alloc] init];
//    self.transformButton = transformButton;
//    [languageBarView addSubview:transformButton];
//    transformButton.toolTip = @"交换语言";
//    transformButton.image = [NSImage imageNamed:@"transform"];
//
//    [transformButton excuteLight:^(id _Nonnull x) {
//        transformButton.contentTintColor = NSColor.blackColor;
//    } drak:^(id _Nonnull x) {
//        transformButton.contentTintColor = NSColor.whiteColor;
//    }];
//
//    [transformButton setClickBlock:^(EZButton * _Nonnull button) {
//        mm_strongify(self)
//        Language from = Configuration.shared.from;
//        Configuration.shared.from = Configuration.shared.to;
//        Configuration.shared.to = from;
//        [self.fromLanguageButton updateWithIndex:[self.translate indexForLanguage:Configuration.shared.from]];
//        [self.toLanguageButton updateWithIndex:[self.translate indexForLanguage:Configuration.shared.to]];
//
//        [self enterAction];
//    }];
//
//
//    self.fromLanguageButton = [PopUpButton mm_make:^(PopUpButton *_Nonnull button) {
//        [languageBarView addSubview:button];
//
//        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//            if ([obj integerValue] == Language_auto) {
//                return @"自动检测";
//            }
//            return LanguageDescFromEnum([obj integerValue]);
//        }]];
//        [button updateWithIndex:[self.translate indexForLanguage:Configuration.shared.from]];
//        mm_weakify(self);
//        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
//            mm_strongify(self);
//            NSInteger from = [[self.translate.languages objectAtIndex:index] integerValue];
//            NSLog(@"from 选中语言 %zd %@", from, LanguageDescFromEnum(from));
//            if (from != Configuration.shared.from) {
//                Configuration.shared.from = from;
//                [self enterAction];
//            }
//        }];
//    }];
//
//
//    self.toLanguageButton = [PopUpButton mm_make:^(PopUpButton *_Nonnull button) {
//        [languageBarView addSubview:button];
//
//        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//            if ([obj integerValue] == Language_auto) {
//                return @"自动选择";
//            }
//            return LanguageDescFromEnum([obj integerValue]);
//        }]];
//        [button updateWithIndex:[self.translate indexForLanguage:Configuration.shared.to]];
//        mm_weakify(self);
//        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
//            mm_strongify(self);
//            NSInteger to = [[self.translate.languages objectAtIndex:index] integerValue];
//            NSLog(@"to 选中语言 %zd %@", to, LanguageDescFromEnum(to));
//            if (to != Configuration.shared.to) {
//                Configuration.shared.to = to;
//                [self enterAction];
//            }
//        }];
//    }];
}

- (void)updateConstraints {
    [self.queryView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
//    [self.languageBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.queryView.mas_bottom).offset(EZMiniVerticalMargin_8);
//        make.left.right.equalTo(self);
//        make.height.mas_equalTo(35);
//        make.bottom.equalTo(self);
//    }];
//
//    CGFloat languageButtonWidth = 90;
//    CGFloat transformButtonWidth = 20;
//
//    [self.transformButton mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(self.languageBarView);
//        make.width.height.mas_equalTo(transformButtonWidth);
//    }];
//
//    CGFloat padding = ((self.width - transformButtonWidth) / 2 - languageButtonWidth) / 2;
//    NSLog(@"query cell padding: %.1f", padding);
//
//    [self.fromLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.centerY.equalTo(self.languageBarView);
//        make.height.mas_equalTo(25);
//        make.left.equalTo(self.languageBarView).offset(padding);
//    }];
//
//    [self.toLanguageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.centerY.width.height.equalTo(self.fromLanguageButton);
//        make.right.equalTo(self.languageBarView).offset(-padding);
//    }];
    
    [super updateConstraints];
}

- (void)enterAction {
    if (self.enterActionBlock) {
        self.enterActionBlock(self.queryView.copiedText);
    }
}


#pragma mark - Setter

//- (void)setQueryText:(NSString *)queryText {
//    _queryText = queryText;
//
//    if (queryText) {
//        self.queryView.queryText = queryText;
//    }
//}

//- (void)setModel:(EZQueryModel *)model {
//    _model = model;
//    
//    self.queryView.model = model;
//}

- (void)setEnterActionBlock:(void (^)(NSString * _Nonnull))enterActionBlock {
    _enterActionBlock = enterActionBlock;
    
    self.queryView.enterActionBlock = enterActionBlock;
}

- (void)setPlayAudioBlock:(void (^)(NSString * _Nonnull))audioActionBlock {
    _playAudioBlock = audioActionBlock;
    
    self.queryView.playAudioBlock = audioActionBlock;
}

- (void)setCopyTextBlock:(void (^)(NSString * _Nonnull))copyActionBlock {
    _copyTextBlock = copyActionBlock;
    
    self.queryView.copyTextBlock = copyActionBlock;
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self);
}

@end
