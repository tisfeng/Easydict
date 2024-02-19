//
//  EZTableTipsCell.m
//  Easydict
//
//  Created by Sharker on 2024/2/18.
//  Copyright © 2024 izual. All rights reserved.
//

#import "EZTableTipsCell.h"
#import "EZHoverButton.h"
#import "NSImage+EZSymbolmage.h"
static const CGFloat EZTableTipsCellTopBarViewHeight = 30;
static const CGFloat EZTableTipsCellContentLabelHeight = 120;

@interface EZTableTipsCell()
@property (nonatomic, strong) NSView *topBarView;
@property (nonatomic, strong) NSImageView *tipsIconImageView;
@property (nonatomic, strong) NSTextField *tipsNameLabel;
@property (nonatomic, strong) NSTextField *tipsContentLabel;
@property (nonatomic, strong) EZHoverButton *moreBtn;
@property (nonatomic, strong) EZHoverButton *solveBtn;
@end

@implementation EZTableTipsCell

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // mas key
    self.topBarView.mas_key = @"topBarView";
    self.tipsIconImageView.mas_key = @"tipsIconImageView";
    self.tipsNameLabel.mas_key = @"tipsNameLabel";
    self.moreBtn.mas_key = @"moreBtn";
    self.solveBtn.mas_key = @"solveBtn";
    
    CGSize iconSize = CGSizeMake(16, 16);
    CGSize buttonSize = CGSizeMake(196, 49);
    
    // constraints
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(EZTableTipsCellTopBarViewHeight);
    }];
    
    [self.tipsIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(iconSize);
    }];
    
    [self.tipsNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tipsIconImageView.mas_right).offset(18);
        make.centerY.equalTo(self.tipsIconImageView.mas_centerY);
    }];
    
    
    [self.tipsContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(9);
        make.top.mas_equalTo(self.topBarView.mas_bottom).offset(12);
        make.height.mas_equalTo(EZTableTipsCellContentLabelHeight);
    }];
    
    [self.solveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.top.mas_equalTo(self.tipsContentLabel.mas_bottom).offset(12);
        make.size.mas_equalTo(buttonSize);
    }];
    
    [self.moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.solveBtn.mas_right).offset(32);
        make.top.mas_equalTo(self.tipsContentLabel);
        make.size.mas_equalTo(buttonSize);
    }];
}

#pragma mark - Accesstor
- (NSView *)topBarView {
    if (!_topBarView) {
        mm_weakify(self);
        _topBarView = [NSView mm_make:^(NSView *_Nonnull view) {
            mm_strongify(self);
            [self addSubview:view];
            view.wantsLayer = YES;
            [view.layer excuteLight:^(CALayer *layer) {
                layer.backgroundColor = [NSColor ez_titleBarBgLightColor].CGColor;
            } dark:^(CALayer *layer) {
                layer.backgroundColor = [NSColor ez_titleBarBgDarkColor].CGColor;
            }];
        }];
    }
    return _topBarView;
}

- (NSImageView *)tipsIconImageView {
    if (!_tipsIconImageView) {
        mm_weakify(self);
        _tipsIconImageView = [NSImageView mm_make:^(NSImageView *imageView) {
            mm_strongify(self);
            [self.topBarView addSubview:imageView];
            [imageView setImage:[NSImage imageNamed:@"Apple Translate"]];
        }];
    }
    return _tipsIconImageView;
}

- (NSTextField *)tipsNameLabel {
    if (!_tipsNameLabel) {
        mm_weakify(self);
        _tipsNameLabel = [NSTextField mm_make:^(NSTextField *label) {
            mm_strongify(self);
            [self.topBarView addSubview:label];
            label.editable = NO;
            label.bordered = NO;
            label.backgroundColor = NSColor.clearColor;
            label.alignment = NSTextAlignmentCenter;
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
            [self addSubview:label];
            label.editable = NO;
            label.bordered = NO;
            label.backgroundColor = NSColor.clearColor;
            label.alignment = NSTextAlignmentLeft;
            [label excuteLight:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextLightColor];
            } dark:^(NSTextField *label) {
                label.textColor = [NSColor ez_resultTextDarkColor];
            }];
        }];
    }
    return _tipsContentLabel;
}

- (EZHoverButton *)moreBtn {
    if (!_moreBtn) {
        _moreBtn = [[EZHoverButton alloc] init];
        [self addSubview:_moreBtn];
        NSImage *moreBtnImage = [NSImage ez_imageWithSymbolName:@"arrow.clockwise.circle"];
        _moreBtn.image = moreBtnImage;
        _moreBtn.title = @"更多解决";
        _moreBtn.toolTip = NSLocalizedString(@"retry", nil);
        [_moreBtn excuteLight:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
        } dark:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
        }];
        mm_weakify(self);
        [_moreBtn setClickBlock:^(EZButton *button) {
            mm_strongify(self);
            if (self.moreBtnClick) {
                self.moreBtnClick();
            }
        }];
    }
    return _moreBtn;
}

- (EZHoverButton *)solveBtn {
    if (!_solveBtn) {
        _solveBtn = [[EZHoverButton alloc] init];
        [self addSubview:_solveBtn];
        NSImage *moreBtnImage = [NSImage ez_imageWithSymbolName:@"arrow.clockwise.circle"];
        _solveBtn.image = moreBtnImage;
        _solveBtn.title = @"更多解决";
        _solveBtn.toolTip = NSLocalizedString(@"retry", nil);
        [_solveBtn excuteLight:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
        } dark:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
        }];
        mm_weakify(self);
        [_solveBtn setClickBlock:^(EZButton *button) {
            mm_strongify(self);
            if (self.moreBtnClick) {
                self.moreBtnClick();
            }
        }];
    }
    return _solveBtn;
}
@end
