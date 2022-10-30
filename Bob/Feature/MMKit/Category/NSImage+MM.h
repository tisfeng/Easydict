//
//  NSImage+MM.h
//  Bob
//
//  Created by ripper on 2019/11/29.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (MM)

+ (NSImage *)mm_imageWithSize:(CGSize)size graphicsContext:(void (^NS_NOESCAPE)(CGContextRef ctx))block;

- (NSData *)mm_PNGData;

- (NSData *)mm_JPEGData;

- (BOOL)mm_writeToFileAsPNG:(NSString *)path;

- (BOOL)mm_writeToFileAsJPEG:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
