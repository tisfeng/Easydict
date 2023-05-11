//
//  NSColor+MyColors.m
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSColor+MyColors.h"

@implementation NSColor (MyColors)

// Main background color
+ (NSColor *)mainViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#FFFFFF"];
}
+ (NSColor *)mainViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#222223"]; // old: 333435, new: 212223
}

// Main border color
+ (NSColor *)mainBorderLightColor {
    return [NSColor mm_colorWithHexString:@"#FFFFFF"];
}
+ (NSColor *)mainBorderDarkColor {
    return [NSColor mm_colorWithHexString:@"#515253"];
}

// Query view background color
+ (NSColor *)queryViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F4F4F4"];
}
+ (NSColor *)queryViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#303132"];
}

// Query text color
+ (NSColor *)queryTextLightColor {
    return [NSColor mm_colorWithHexString:@"#262626"];
}
+ (NSColor *)queryTextDarkColor {
    return [NSColor mm_colorWithHexString:@"#DFDFDF"];
}

// Result text color
+ (NSColor *)resultTextLightColor {
    return [NSColor queryTextLightColor];
}
+ (NSColor *)resultTextDarkColor {
    return [NSColor queryTextDarkColor];
}

// Result view title bar color
+ (NSColor *)titleBarBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F1F1F1"];
}
+ (NSColor *)titleBarBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#2D2E2F"];
}

// Result view background color
+ (NSColor *)resultViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F6F6F6"];
}
+ (NSColor *)resultViewBgDarkColor {
    return [NSColor queryViewBgDarkColor];
}

// Button hover color
+ (NSColor *)buttonHoverLightColor {
    return [NSColor mm_colorWithHexString:@"#E2E2E2"];
}
+ (NSColor *)buttonHoverDarkColor {
    return [NSColor mainBorderDarkColor];
}

// Image tint color
+ (NSColor *)imageTintLightColor {
    return [NSColor blackColor];
}
+ (NSColor *)imageTintDarkColor {
    return [NSColor whiteColor];
}

+ (NSColor *)imageTintBlueColor {
    return [NSColor mm_colorWithHexString:@"#1296DB"];
}

@end
