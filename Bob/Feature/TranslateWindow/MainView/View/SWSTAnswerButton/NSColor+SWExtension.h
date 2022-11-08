//
//  NSColor+SWExtension.h
//  SWST_iOS
//
//  Created by luoming on 28/11/2016.
//  Copyright © 2016 cvte. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (hex)

+ (NSColor*)colorWithRGB:(uint32_t)rgbValue;
+ (NSColor*)colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha;
+ (NSColor *)colorWithRGBA:(uint32_t)rgbaValue;

@end
