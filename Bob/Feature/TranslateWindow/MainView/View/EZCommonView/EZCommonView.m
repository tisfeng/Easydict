//
//  EDAudioView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZCommonView.h"
#import "EZHoverButton.h"

static const CGFloat ktMargin = 5;

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
    self.layer.cornerRadius = 8;
    [self.layer excuteLight:^(id _Nonnull x) {
        [x setBackgroundColor:NSColor.queryViewBgLightColor.CGColor];
    } drak:^(id _Nonnull x) {
        [x setBackgroundColor:NSColor.queryViewBgDarkColor.CGColor];
    }];
    
    
    EZHoverButton *audioButton = [[EZHoverButton alloc] init];
    [self addSubview:audioButton];
    self.audioButton = audioButton;
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"播放音频";
    
    
    mm_weakify(self)
    [audioButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"audioActionBlock");
        
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
    textCopyButton.toolTip = @"复制";
    
    [textCopyButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"copyActionBlock");
        
        mm_strongify(self)
        if (self.copyTextBlock) {
            self.copyTextBlock(self.copiedText);
        }        
    }];
    textCopyButton.mas_key = @"copyButton";
}

- (void)updateConstraints {
    [self.audioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-ktMargin);
        make.left.offset(ktMargin + 2);
        make.width.height.equalTo(@23);
    }];
    
    [self.textCopyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioButton.mas_right).offset(0);
        make.bottom.equalTo(self.audioButton);
        make.width.height.equalTo(self.audioButton);
    }];
    
    [super updateConstraints];
}

@end
