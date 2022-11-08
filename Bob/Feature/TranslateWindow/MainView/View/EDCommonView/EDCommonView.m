//
//  EDAudioView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EDCommonView.h"
#import "EDHoverButton.h"

static const CGFloat kLeftMargin = 8;
static const CGFloat kBottomMargin = 8;

@interface EDCommonView ()

@end


@implementation EDCommonView


- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}


- (void)setupUI {
    self.wantsLayer = YES;
    [self.layer excuteLight:^(id _Nonnull x) {
        [x setBackgroundColor:LightBgColor.CGColor];
    } drak:^(id _Nonnull x) {
        [x setBackgroundColor:DarkBgColor.CGColor];
    }];
    self.layer.cornerRadius = 8;
    
    
    EDHoverButton *audioButton = [[EDHoverButton alloc] init];
    [self addSubview:audioButton];
    self.audioButton = audioButton;
    
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"播放音频";
    
    
    mm_weakify(self)
    [audioButton setActionBlock:^(EDHoverButton * _Nonnull button) {
        NSLog(@"audioActionBlock");
        
        mm_strongify(self)
        if (self.audioActionBlock) {
            self.audioActionBlock(self.queryText);
        }
    }];
    audioButton.mas_key = @"audioButton";
    
    
    EDHoverButton *textCopyButton = [[EDHoverButton alloc] init];
    [self addSubview:textCopyButton];
    self.textCopyButton = textCopyButton;
    
    NSImage *copyImage = [NSImage imageNamed:@"copy"];
    textCopyButton.title = @"";
    textCopyButton.image = copyImage;
    textCopyButton.toolTip = @"复制";
    textCopyButton.normalImage = copyImage;
    
    [textCopyButton setActionBlock:^(EDHoverButton * _Nonnull button) {
        NSLog(@"copyActionBlock");
        
        mm_strongify(self)
        if (self.copyActionBlock) {
            self.copyActionBlock(self.queryText);
        }
    }];
    textCopyButton.mas_key = @"copyButton";
}

- (void)updateConstraints {
    [self.audioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-kBottomMargin);
        make.left.offset(kLeftMargin);
        make.width.height.equalTo(@25);
    }];
    
    [self.textCopyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioButton.mas_right).offset(3);
        make.bottom.equalTo(self.audioButton);
        make.width.height.equalTo(self.audioButton);
    }];
    
    [super updateConstraints];
}

@end
