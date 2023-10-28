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
    self.contentTintColor = NSColor.ez_imageTintColor;
    self.backgroundHoverColor = [
        NSColor ez_dynamicColorLight:[NSColor mm_colorWithHexString:@"#E6E6E6"]
                                dark:[NSColor mm_colorWithHexString:@"#3D3F3F"]
    ];
    self.backgroundHighlightColor = [
        NSColor ez_dynamicColorLight:[NSColor mm_colorWithHexString:@"#DADADA"]
                                dark:[NSColor mm_colorWithHexString:@"#484848"]
    ];
}

@end
