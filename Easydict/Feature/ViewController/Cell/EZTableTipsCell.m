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

@interface EZTableTipsCell()
@property (nonatomic, strong) NSView *contentView;
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
    
    
    [self.tipsContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.top.mas_equalTo(self.tipsNameLabel.mas_bottom).offset(12);
    }];
    
    [self.solveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(9);
        make.top.mas_equalTo(self.tipsContentLabel.mas_bottom).offset(12);
        make.size.mas_equalTo(buttonSize);
    }];
    
    [self.moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.solveBtn.mas_right).offset(20);
        make.top.mas_equalTo(self.solveBtn);
        make.size.mas_equalTo(buttonSize);
    }];
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
            [self addSubview:label];
            label.editable = NO;
            label.bordered = NO;
            label.backgroundColor = NSColor.clearColor;
            label.alignment = NSTextAlignmentLeft;
            label.stringValue = @"测试";
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
        NSImage *solveBtnImage = [NSImage ez_imageWithSymbolName:@"exclamationmark.warninglight"];
        _solveBtn.image = solveBtnImage;
        _solveBtn.imagePosition = NSImageLeft;
        _solveBtn.title = NSLocalizedString(@"tips_solve", nil);
        _solveBtn.edgeInsets = NSEdgeInsetsMake(0, 3, 0, 3);
        [_solveBtn excuteLight:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
        } dark:^(NSButton *button) {
            button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
        }];
        mm_weakify(self);
        [_solveBtn setClickBlock:^(EZButton *button) {
            mm_strongify(self);
            if (self.solveBtnClick) {
                self.solveBtnClick();
            }
        }];
    }
    return _solveBtn;
}
@end
