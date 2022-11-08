//
//  EDAudioView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EDCommonView.h"
#import "EDButton.h"

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
    
    
    EDButton *audioButton = [[EDButton alloc] init];
    [self addSubview:audioButton];
    self.audioButton = audioButton;
    
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"播放音频";
   
    
    mm_weakify(self)
    [audioButton setActionBlock:^(EDButton * _Nonnull button) {
        mm_strongify(self)
        if (self.audioActionBlock) {
            NSLog(@"audioActionBlock");
            self.audioActionBlock(self.queryText);
        }
    }];
    audioButton.mas_key = @"audioButton";

    
    
    EDButton *copyButton = [[EDButton alloc] init];
    [self addSubview:copyButton];
    self.textCopyButton = copyButton;
    
    copyButton.image = [NSImage imageNamed:@"copy"];
    copyButton.toolTip = @"复制";
    
    
    [copyButton setActionBlock:^(EDButton * _Nonnull button) {
        mm_strongify(self)
        if (self.copyActionBlock) {
            NSLog(@"copyActionBlock");
            self.copyActionBlock(self.queryText);
        }
    }];
    copyButton.mas_key = @"copyButton";

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSTrackingArea *copyTrackingArea = [[NSTrackingArea alloc]
                                            initWithRect:[self.textCopyButton bounds]
                                            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                            owner:self
                                            userInfo:nil];
        [self.textCopyButton addTrackingArea:copyTrackingArea];
        
        NSTrackingArea *playTrackingArea = [[NSTrackingArea alloc]
                                            initWithRect:[self.audioButton bounds]
                                            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                            owner:self
                                            userInfo:nil];
        [self.audioButton addTrackingArea:playTrackingArea];
    });
}

- (void)updateConstraints {
    [self.audioButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-kBottomMargin);
        make.left.offset(kLeftMargin);
        make.width.height.equalTo(@23);
    }];
    
    [self.textCopyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioButton.mas_right).offset(2);
        make.bottom.equalTo(self.audioButton);
        make.width.height.equalTo(self.audioButton);
    }];
    
    [super updateConstraints];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    CGPoint point = theEvent.locationInWindow;
    point = [self convertPoint:point fromView:nil];
    
    [self excuteLight:^(id x) {
        NSColor *highlightBgColor = [NSColor mm_colorWithHexString:@"#E2E2E2"];
        [self hightlightCopyButtonBgColor:highlightBgColor point:point];
    } drak:^(id x) {
        [self hightlightCopyButtonBgColor:DarkBorderColor point:point];
    }];
}

- (void)hightlightCopyButtonBgColor:(NSColor *)color point:(CGPoint)point {
    if (CGRectContainsPoint(self.textCopyButton.frame, point)) {
        [[self.textCopyButton cell] setBackgroundColor:color];
    } else if (CGRectContainsPoint(self.audioButton.frame, point)) {
        [[self.audioButton cell] setBackgroundColor:color];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [[self.textCopyButton cell] setBackgroundColor:NSColor.clearColor];
    [[self.audioButton cell] setBackgroundColor:NSColor.clearColor];
}

@end
