//
//  HoverButton.m
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZHoverButton.h"
#import "NSObject+EZDarkMode.h"

@implementation EZHoverButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self ez_setup];
    }
    return self;
}

- (void)ez_setup {
    self.cornerRadius = 5;
    
    [self executeOnAppearanceChange:^(EZButton *button, BOOL isDarkMode) {
        button.contentTintColor = isDarkMode ? [NSColor ez_imageTintDarkColor] : [NSColor ez_imageTintLightColor];
        button.backgroundHoverColor = [NSColor mm_colorWithHexString:isDarkMode ? @"#3D3F3F" : @"#E6E6E6"];
        button.backgroundHighlightColor = [NSColor mm_colorWithHexString:isDarkMode ? @"#484848" : @"#DADADA"];
    }];
}

@end
