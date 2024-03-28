//
//  EZSymbolImageButton.m
//  Easydict
//
//  Created by tisfeng on 2023/4/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZSymbolImageButton.h"
#import "NSImage+EZSymbolmage.h"

@implementation EZSymbolImageButton

+ (instancetype)buttonWithSybolImageName:(NSString *)sybolImageName {
    EZSymbolImageButton *button = [[EZSymbolImageButton alloc] init];
    NSImage *audioImage = [NSImage ez_imageWithSymbolName:sybolImageName];
    button.image = audioImage;
    
    [button excuteLight:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintLightColor]];
    } dark:^(NSButton *button) {
        button.image = [button.image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
    }];
    
    return button;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
