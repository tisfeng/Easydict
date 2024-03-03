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
    NSImage *copyImage = [NSImage imageNamed:@"copy"];
    copyImage = [copyImage resizeToSize:CGSizeMake(16, 16)];
    self.image = copyImage;
    
    [self excuteLight:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];
    
    NSString *action = EZLocalizedString(@"copy_text");
    self.toolTip = [NSString stringWithFormat:@"%@", action];
}

@end
