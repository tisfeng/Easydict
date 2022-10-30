//
//  NSImage+MM.m
//  Bob
//
//  Created by ripper on 2019/11/29.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSImage+MM.h"

@implementation NSImage (MM)

/// https://stackoverflow.com/questions/10627557/mac-os-x-drawing-into-an-offscreen-nsgraphicscontext-using-cgcontextref-c-funct
+ (NSImage *)mm_imageWithSize:(CGSize)size graphicsContext:(void (^NS_NOESCAPE)(CGContextRef ctx))block {
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:size.width
                                                                    pixelsHigh:size.height
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSDeviceRGBColorSpace
                                                                  bitmapFormat:NSAlphaFirstBitmapFormat
                                                                   bytesPerRow:0
                                                                  bitsPerPixel:0];
    
    NSGraphicsContext *g = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:g];

    if (@available(macOS 10.14, *)) {
        block(g.CGContext);
    } else {
        block(g.graphicsPort);
    }
    
    [NSGraphicsContext restoreGraphicsState];

    NSImage *newImage = [[NSImage alloc] initWithSize:size];
    [newImage addRepresentation:rep];
    return newImage;
}

/// https://stackoverflow.com/questions/3038820/how-to-save-a-nsimage-as-a-new-file
- (NSData *)mm_PNGData {
    NSData *tiffData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *data = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return data;
}

- (NSData *)mm_JPEGData {
    NSData *tiffData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *data = [imageRep representationUsingType:NSBitmapImageFileTypeJPEG
                                          properties:@{NSImageCompressionFactor: @1.0}];
    return data;
}

- (BOOL)mm_writeToFileAsPNG:(NSString *)path {
    if (!path.length) {
        return NO;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *directory = [path stringByDeletingLastPathComponent];
    if (!directory.length) {
        return NO;
    }
    if (![manager fileExistsAtPath:directory]) {
        if (![manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]) {
            return NO;
        }
    }
    NSData *data = [self mm_PNGData];
    BOOL result = [data writeToFile:path atomically:NO];
    return result;
}

- (BOOL)mm_writeToFileAsJPEG:(NSString *)path {
    if (!path.length) {
        return NO;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *directory = [path stringByDeletingLastPathComponent];
    if (!directory.length) {
        return NO;
    }
    if (![manager fileExistsAtPath:directory]) {
        if (![manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]) {
            return NO;
        }
    }
    NSData *data = [self mm_JPEGData];
    BOOL result = [data writeToFile:path atomically:NO];
    return result;
}


@end
