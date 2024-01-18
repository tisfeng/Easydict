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


/// Return a system symbol image, if < macos(11.0), return a normal image with image name.
/// - Parameters:
///   - name: system symbol image name or assets image name
///   - size: image size
+ (NSImage *)ez_imageWithSymbolName:(NSString *)name size:(CGSize)size {
    NSImage *image;
    if (@available(macOS 11.0, *)) {
        image = [NSImage imageWithSystemSymbolName:name accessibilityDescription:nil];
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
        }
    } else {
        // Fallback on earlier versions
        NSLog(@"ez_imageWithSymbolName: %@", name);
        image = [NSImage imageNamed:name];
    }
    image = [image resizeToSize:size];
    return image;
}

@end
