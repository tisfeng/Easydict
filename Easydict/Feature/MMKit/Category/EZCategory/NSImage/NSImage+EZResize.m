//
//  NSImage+EZResize.m
//  Easydict
//
//  Created by tisfeng on 2022/11/24.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSImage+EZResize.h"

@implementation NSImage (EZResize)

- (NSImage *)resizeToSize:(NSSize)size {
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [self drawInRect:NSMakeRect(0, 0, size.width, size.height)
            fromRect:NSZeroRect
           operation:NSCompositingOperationSourceOver
            fraction:1.0];
    [image unlockFocus];
    return image;
}

@end
