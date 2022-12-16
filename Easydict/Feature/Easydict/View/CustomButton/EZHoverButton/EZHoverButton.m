//
//  HoverButton.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZHoverButton.h"

@implementation EZHoverButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self ez_setup];
    }
    return self;
}

- (void)ez_setup {
    self.cornerRadius = 5;
    
    [self excuteLight:^(EZButton *button) {
        button.contentTintColor = [NSColor imageTintLightColor];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#DADADA"]; 
    } drak:^(EZButton *button) {
        button.contentTintColor = [NSColor imageTintDarkColor];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#353535"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#454545"];
    }];
}

@end
