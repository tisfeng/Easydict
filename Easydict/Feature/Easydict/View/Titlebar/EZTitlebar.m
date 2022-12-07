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
#import "NSObject+EZDarkMode.h"

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
    //    EZTitleBarMoveView *moveView = [[EZTitleBarMoveView alloc] init];
    //    moveView.wantsLayer = YES;
    //    moveView.layer.backgroundColor = NSColor.clearColor.CGColor;
    //    [self addSubview:moveView];
    //    [moveView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(self);
    //    }];
    
    CGFloat kButtonWidth = 26;
    CGFloat kImagenWidth = 22;
    CGFloat kButtonPadding = 4;
    
    CGSize buttonSize = CGSizeMake(kButtonWidth, kButtonWidth);
    CGSize imageSize = CGSizeMake(kImagenWidth, kImagenWidth);
    
    EZLinkButton *pinButton = [[EZLinkButton alloc] init];
    [self addSubview:pinButton];
    self.pinButton = pinButton;
    pinButton.contentTintColor = [NSColor clearColor];
    pinButton.toolTip = @"Pin";
    [pinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        CGFloat pinButtonWidth = 25;
        make.width.height.mas_equalTo(pinButtonWidth);
        make.left.inset(10);
        make.top.equalTo(self).offset(EZTitlebarHeight_28 - pinButtonWidth);
    }];
    NSView *lastView;
    
    
    EZLinkButton *googleButton = [[EZLinkButton alloc] init];
    [self addSubview:googleButton];
    self.googleButton = googleButton;
    
    googleButton.link = @"https://www.google.com/search?q=%@";
    googleButton.image = [[NSImage imageNamed:@"Browser"] resizeToSize:imageSize];
    googleButton.toolTip = @"Google";
    googleButton.contentTintColor = NSColor.clearColor;
    
    [googleButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(EZTitlebarHeight_28 - kButtonWidth);
        make.size.mas_equalTo(buttonSize);
        if (lastView) {
            make.right.equalTo(lastView.mas_left).offset(-kButtonPadding);
        } else {
            make.right.equalTo(self).offset(-9);
        }
    }];
    lastView = googleButton;
    
    
    EZLinkButton *eudicButton = [[EZLinkButton alloc] init];
    [self addSubview:eudicButton];
    self.eudicButton = eudicButton;
    
    // !!!: Note that some applications have multiple channel versions. Ref: https://github.com/tisfeng/Raycast-Easydict/issues/16
    BOOL installedEudic = [self checkInstalledApp:@[@"com.eusoft.freeeudic", @"com.eusoft.eudic"]];
    eudicButton.hidden = !installedEudic;
    if (installedEudic) {
        self.favoriteButton = eudicButton;
    }
    
    eudicButton.link = @"eudic://dict/%@";
    eudicButton.image = [[NSImage imageNamed:@"Eudic"] resizeToSize:imageSize];
    eudicButton.toolTip = @"Eudic";
    eudicButton.contentTintColor = NSColor.clearColor;
    
    [eudicButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView);
        make.size.mas_equalTo(buttonSize);
        if (lastView) {
            make.right.equalTo(lastView.mas_left).offset(-kButtonPadding);
        } else {
            make.right.equalTo(self).offset(-kButtonPadding);
        }
    }];
    
    lastView = eudicButton;
}


/// Check if installed app according to bundle id array
- (BOOL)checkInstalledApp:(NSArray<NSString *> *)bundleIds {
    for (NSString *bundleId in bundleIds) {
        if ([[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleId]) {
            return YES;
        }
    }
    return NO;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
