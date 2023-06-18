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
+ (NSColor *)ez_mainViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#FFFFFF"];
}
+ (NSColor *)ez_mainViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#232325"];
}

// Main border color
+ (NSColor *)ez_mainBorderLightColor {
    return [NSColor mm_colorWithHexString:@"#FFFFFF"];
}
+ (NSColor *)ez_mainBorderDarkColor {
    return [NSColor mm_colorWithHexString:@"#515253"];
}

// Query view background color
+ (NSColor *)ez_queryViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F4F4F4"];
}
+ (NSColor *)ez_queryViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#303132"];
}

// Query text color
+ (NSColor *)ez_queryTextLightColor {
    return [NSColor mm_colorWithHexString:@"#262626"];
}
+ (NSColor *)ez_queryTextDarkColor {
    return [NSColor mm_colorWithHexString:@"#E0E0E0"];
}

// Result text color
+ (NSColor *)ez_resultTextLightColor {
    return [NSColor ez_queryTextLightColor];
}
+ (NSColor *)ez_resultTextDarkColor {
    return [NSColor ez_queryTextDarkColor];
}

// Result view title bar color
+ (NSColor *)ez_titleBarBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F1F1F1"];
}
+ (NSColor *)ez_titleBarBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#2C2D2E"];
}

// Result view background color
+ (NSColor *)ez_resultViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F6F6F6"];
}
+ (NSColor *)ez_resultViewBgDarkColor {
    return [NSColor ez_queryViewBgDarkColor];
}

// Button hover color
+ (NSColor *)ez_buttonHoverLightColor {
    return [NSColor mm_colorWithHexString:@"#E2E2E2"];
}
+ (NSColor *)ez_buttonHoverDarkColor {
    return [NSColor ez_mainBorderDarkColor];
}

// Image tint color
+ (NSColor *)ez_imageTintLightColor {
    return [NSColor blackColor];
}
+ (NSColor *)ez_imageTintDarkColor {
    return [NSColor whiteColor];
}

+ (NSColor *)ez_imageTintBlueColor {
    return [NSColor mm_colorWithHexString:@"#1296DB"];
}

+ (NSColor *)ez_blueTitleColor {
    return [NSColor mm_colorWithHexString:@"#007AFF"];
}

+ (NSColor *)ez_tableRowViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#FFFFFF"];
}
+ (NSColor *)ez_tableRowViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#28292A"];
}

@end
