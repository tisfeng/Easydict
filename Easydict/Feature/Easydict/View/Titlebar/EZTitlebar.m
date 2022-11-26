//
//  EZTitlebar.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTitlebar.h"
#import "EZTitleBarMoveView.h"
#import "NSView+EZWindowType.h"
#import "NSImage+EZResize.h"

static CGFloat kButtonWidth = 20;
static CGFloat kButtonPadding = 12;

@interface EZTitlebar ()

@end

@implementation EZTitlebar

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    EZTitleBarMoveView *moveView = [[EZTitleBarMoveView alloc] init];
    moveView.wantsLayer = YES;
    moveView.layer.backgroundColor = NSColor.clearColor.CGColor;
    [self addSubview:moveView];
    [moveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    EZHoverButton *pinButton = [[EZHoverButton alloc] init];
    [self addSubview:pinButton];
    self.pinButton = pinButton;
    pinButton.cornerRadius = 2;
    [pinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(23, 23));
        make.left.inset(10);
        make.top.equalTo(self).offset(5);
    }];
    
    [pinButton setMouseEnterBlock:^(EZButton * _Nonnull button) {
        NSColor *lightHighlightColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
        NSColor *darkHighlightColor = [NSColor mm_colorWithHexString:@"#484848"];
        [button excuteLight:^(EZButton *button) {
            button.backgroundHoverColor = lightHighlightColor;
            button.backgroundHighlightColor = lightHighlightColor;
        } drak:^(EZButton *button) {
            button.backgroundHoverColor = darkHighlightColor;
            button.backgroundHighlightColor = darkHighlightColor;
        }];
    }];
    [pinButton setMouseExitedBlock:^(EZButton * _Nonnull button) {
        button.backgroundColor = NSColor.clearColor;
    }];
    
    NSView *lastView;
    
    EZButton *eudicButton = [[EZButton alloc] init];
    [self addSubview:eudicButton];
    self.eudicButton = eudicButton;
    eudicButton.title = @"";
    eudicButton.image = [NSImage imageNamed:@"Eudic"];
    eudicButton.toolTip = @"查询 Eudic";
    eudicButton.contentTintColor = NSColor.clearColor;
    
    [self.eudicButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(kButtonWidth);
        make.right.equalTo(self).offset(-kButtonPadding);
    }];
    lastView = eudicButton;
    
    
    EZButton *chromeButton = [[EZButton alloc] init];
    [self addSubview:chromeButton];
    self.chromeButton = chromeButton;
    chromeButton.title = @"";
    chromeButton.image = [NSImage imageNamed:@"Chrome"];
    chromeButton.toolTip = @"Google";
    chromeButton.contentTintColor = NSColor.clearColor;
    
    [self.chromeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(kButtonWidth);
        if (lastView) {
            make.right.equalTo(lastView.mas_left).offset(-kButtonPadding);
        } else {
            make.right.equalTo(self).offset(-kButtonPadding);
        }
    }];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
