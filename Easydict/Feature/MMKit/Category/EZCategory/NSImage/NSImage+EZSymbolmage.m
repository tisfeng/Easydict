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
    NSImage *image = [self ez_imageWithSymbolName:name size:size];
    return image;
}

+ (NSImage *)ez_imageWithSymbolName:(NSString *)name size:(CGSize)size {
    NSImage *image = [NSImage imageWithSystemSymbolName:name accessibilityDescription:nil];
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        image = [image resizeToSize:size];
    }
    return image;
}

@end
