//
//  NSColor+SWExtension.m
//  SWST_iOS
//
//  Created by luoming on 28/11/2016.
//  Copyright © 2016 cvte. All rights reserved.
//

#import "NSColor+SWExtension.h"

@implementation NSColor (hex)


+ (NSColor*)colorWithRGB:(uint32_t)rgbValue
{
    float red = ((rgbValue & 0xFF0000) >> 16) / 255.0;
    float green = ((rgbValue & 0x00FF00) >> 8) / 255.0;
    float blue = ((rgbValue & 0x0000FF)) / 255.0;
    return [NSColor colorWithRed:red green:green blue:blue alpha:1.0];
}
+ (NSColor*)colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha
{
    float red = ((rgbValue & 0xFF0000) >> 16) / 255.0;
    float green = ((rgbValue & 0x00FF00) >> 8) / 255.0;
    float blue = ((rgbValue & 0x0000FF)) / 255.0;
    return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}
+ (NSColor *)colorWithRGBA:(uint32_t)rgbaValue
{
    float alpha = ((rgbaValue & 0xFF000000) >> 24) / 255.0;
    float red = ((rgbaValue & 0x00FF0000) >> 16) / 255.0;
    float green = ((rgbaValue & 0x0000FF00) >> 8) / 255.0;
    float blue = (rgbaValue & 0x000000FF) / 255.0;
    return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
