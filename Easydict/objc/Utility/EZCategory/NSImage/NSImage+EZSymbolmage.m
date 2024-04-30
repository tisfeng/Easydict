//
//  NSImage+EZSymbolmage.m
//  Easydict
//
//  Created by tisfeng on 2023/4/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSImage+EZSymbolmage.h"
#import "NSImage+EZResize.h"

@implementation NSImage (EZSymbolmage)

+ (NSImage *)ez_imageWithSymbolName:(NSString *)name {
    CGSize size = CGSizeMake(EZAudioButtonImageWidth_16, EZAudioButtonImageWidth_16);
    NSImage *image = [self ez_imageWithSymbolName:name size:size scale:NSImageSymbolScaleSmall];
    return image;
}

+ (NSImage *)ez_imageWithSymbolName:(NSString *)name size:(CGSize)size scale:(NSImageSymbolScale)scale {
    NSImage *image = [[NSImage imageWithSystemSymbolName:name accessibilityDescription:nil] imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithScale:scale]];
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        image = [image resizeToSize:size];
    }
    return image;
}

@end
