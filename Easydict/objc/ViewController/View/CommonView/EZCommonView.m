//
//  EDAudioView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZCommonView.h"
#import "EZHoverButton.h"
#import "EZConst.h"

@interface EZCommonView ()

@end


@implementation EZCommonView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.wantsLayer = YES;
    self.layer.cornerRadius = EZCornerRadius_8;
    [self.layer excuteLight:^(id _Nonnull x) {
        [x setBackgroundColor:[NSColor ez_queryViewBgLightColor].CGColor];
    } dark:^(id _Nonnull x) {
        [x setBackgroundColor:[NSColor ez_queryViewBgDarkColor].CGColor];
    }];

    
    EZHoverButton *audioButton = [[EZHoverButton alloc] init];
    [self addSubview:audioButton];
    self.audioButton = audioButton;
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"Play";
    
    
    mm_weakify(self)
    [audioButton setClickBlock:^(EZButton * _Nonnull button) {
        MMLogInfo(@"audioActionBlock");
        
        mm_strongify(self)
        if (self.playAudioBlock) {
            self.playAudioBlock(self.copiedText);
        }
    }];
    audioButton.mas_key = @"audioButton";
    
    
    EZHoverButton *textCopyButton = [[EZHoverButton alloc] init];
    [self addSubview:textCopyButton];
    self.textCopyButton = textCopyButton;
    
    textCopyButton.image = [NSImage imageNamed:@"copy"];
    textCopyButton.toolTip = @"Copy";
    
    [textCopyButton setClickBlock:^(EZButton * _Nonnull button) {
        MMLogInfo(@"copyActionBlock");
        
        mm_strongify(self)
        if (self.copyTextBlock) {
            self.copyTextBlock(self.copiedText);
        }        
    }];
    textCopyButton.mas_key = @"copyButton";
}

- (void)updateConstraints {
    [self.audioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-5);
        make.left.offset(8);
        make.width.height.mas_equalTo(EZAudioButtonWidthHeight_24);
    }];
    
    [self.textCopyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioButton.mas_right).offset(1);
        make.width.height.bottom.equalTo(self.audioButton);
    }];
    
    [super updateConstraints];
}

@end
