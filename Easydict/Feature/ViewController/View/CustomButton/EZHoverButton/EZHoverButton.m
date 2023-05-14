//
//  HoverButton.m
//  Easydict
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
        button.contentTintColor = [NSColor ez_imageTintLightColor];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#DADADA"]; 
    } dark:^(EZButton *button) {
        button.contentTintColor = [NSColor ez_imageTintDarkColor];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#3D3F3F"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#484848"];
    }];
}

@end
