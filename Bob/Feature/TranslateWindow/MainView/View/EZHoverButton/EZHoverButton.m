//
//  HoverButton.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZHoverButton.h"

@implementation EZHoverButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.cornerRadius = 5;
    
    [self excuteLight:^(EZButton *button) {
        button.contentTintColor = NSColor.blackColor;
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
        button.backgroundHighlightColor = NSColor.lightGrayColor;
    } drak:^(EZButton *button) {
        button.contentTintColor = NSColor.whiteColor;
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#353535"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#454545"];
    }];
}

@end
