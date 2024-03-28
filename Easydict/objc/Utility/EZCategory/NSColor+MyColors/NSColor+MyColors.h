//
//  NSColor+MyColors.h
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSColor (MyColors)

// Main background color
+ (NSColor *)ez_mainViewBgLightColor;
+ (NSColor *)ez_mainViewBgDarkColor;

// Main border color
+ (NSColor *)ez_mainBorderLightColor;
+ (NSColor *)ez_mainBorderDarkColor;

// Query view background color
+ (NSColor *)ez_queryViewBgLightColor;
+ (NSColor *)ez_queryViewBgDarkColor;

// Query text color
+ (NSColor *)ez_queryTextLightColor;
+ (NSColor *)ez_queryTextDarkColor;

// Result text color
+ (NSColor *)ez_resultTextLightColor;
+ (NSColor *)ez_resultTextDarkColor;

// Result view top bar color
+ (NSColor *)ez_titleBarBgLightColor;
+ (NSColor *)ez_titleBarBgDarkColor;

// Result view background color
+ (NSColor *)ez_resultViewBgLightColor;
+ (NSColor *)ez_resultViewBgDarkColor;

// Button hover color
+ (NSColor *)ez_buttonHoverLightColor;
+ (NSColor *)ez_buttonHoverDarkColor;

// Image tint color
+ (NSColor *)ez_imageTintLightColor;
+ (NSColor *)ez_imageTintDarkColor;

+ (NSColor *)ez_imageTintBlueColor;

+ (NSColor *)ez_blueTitleColor;

+ (NSColor *)ez_tableRowViewBgLightColor;
+ (NSColor *)ez_tableRowViewBgDarkColor;

@end

NS_ASSUME_NONNULL_END
