//
//  EZCopyButton.m
//  Easydict
//
//  Created by tisfeng on 2023/4/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZCopyButton.h"
#import "NSImage+EZResize.h"

@implementation EZCopyButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    NSImage *baseImage = [[NSImage imageNamed:@"copy"] resizeToSize:CGSizeMake(16, 16)];

    [self executeOnAppearanceChange:^(NSButton *button, BOOL isDarkMode) {
        NSColor *tintColor = isDarkMode ? [NSColor ez_imageTintDarkColor] : [NSColor ez_imageTintLightColor];
        button.image = [baseImage imageWithTintColor:tintColor];
    }];
    
    NSString *action = NSLocalizedString(@"copy_text", nil);
    self.toolTip = [NSString stringWithFormat:@"%@", action];
}

@end
