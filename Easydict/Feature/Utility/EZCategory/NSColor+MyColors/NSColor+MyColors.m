//
//  NSColor+MyColors.m
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSColor+MyColors.h"
#import "GeneratedAssetSymbols.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSColor (MyColors)
+ (NSColor *)ez_dynamicColorLight:(NSColor *)light dark:(NSColor *)dark {
    return [NSColor colorWithName:nil dynamicProvider:^NSColor * _Nonnull(NSAppearance * _Nonnull appearance) {
        __auto_type name = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
        if ([name isEqualToString:NSAppearanceNameDarkAqua]) {
            return dark;
        } else {
            return light;
        }
    }];
}

+ (NSColor *)ez_mainViewBgColor {
    return [NSColor colorNamed:ACColorNameMainViewBg];
}

+ (NSColor *)ez_mainBorderColor {
    return [NSColor colorNamed:ACColorNameMainBorder];
}

+ (NSColor *)ez_queryTexColor {
    return [NSColor colorNamed:ACColorNameQueryText];
}

+ (NSColor *)ez_queryViewBgColor {
    return [NSColor colorNamed:ACColorNameQueryViewBg];
}

+ (NSColor *)ez_resultTexColor {
    return [NSColor colorNamed:ACColorNameResultText];
}

+ (NSColor *)ez_resultTextLightColor {
    return [NSColor mm_colorWithHexString:@"#262626"];
}
+ (NSColor *)ez_resultTextDarkColor {
    return [NSColor mm_colorWithHexString:@"#E0E0E0"];
}

+ (NSColor *)ez_resultViewBgColor {
    return [NSColor colorNamed:ACColorNameResultViewBg];
}

+ (NSColor *)ez_resultViewBgLightColor {
    return [NSColor mm_colorWithHexString:@"#F6F6F6"];
}
+ (NSColor *)ez_resultViewBgDarkColor {
    return [NSColor mm_colorWithHexString:@"#303132"];
}

+ (NSColor *)ez_titleBarBgColor {
    return [NSColor colorNamed:ACColorNameTitleBarBg];
}

+ (NSColor *)ez_buttonHoverColor {
    return [NSColor colorNamed:ACColorNameButtonHover];
}

+ (NSColor *)ez_imageTintColor {
    return [NSColor ez_dynamicColorLight:NSColor.blackColor dark:NSColor.whiteColor];
}

+ (NSColor *)ez_imageTintBlueColor {
    return [NSColor mm_colorWithHexString:@"#1296DB"];
}

+ (NSColor *)ez_blueTitleColor {
    return [NSColor mm_colorWithHexString:@"#007AFF"];
}

+ (NSColor *)ez_tableRowViewBgColor {
    return [NSColor colorNamed:ACColorNameTableRowViewBg];
}

@end

NS_ASSUME_NONNULL_END
