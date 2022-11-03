//
//  NSColor+MyColors.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "NSColor+MyColors.h"

@implementation NSColor (MyColors)

// Main background color
+ (NSColor *)mainViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#FFFFFF"];
}
+ (NSColor *)mainViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#333435"];
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
    return [NSColor mm_colorWithHexString:@"#F6F6F6"];
}
+ (NSColor *)queryViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#252627"];
}

// Query text color
+ (NSColor *)queryTextLightColor {
    return [NSColor mm_colorWithHexString:@"#262626"];
}
+ (NSColor *)queryTextDarkColor {
    return [NSColor mm_colorWithHexString:@"#DEDEDE"];
}

// Result text color
+ (NSColor *)resultTextLightColor {
    return [NSColor queryTextLightColor];
}
+ (NSColor *)resultTextDarkColor {
    return [NSColor queryTextDarkColor];
}

// Result view top bar color
+ (NSColor *)topBarBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F1F1F1"];
}
+ (NSColor *)topBarBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#212223"];
}

// Result view background color
+ (NSColor *)resultViewBgLightColor {
    return [NSColor queryViewBgLightColor];
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

@end
