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
+ (NSColor *)mainViewBgLightColor;
+ (NSColor *)mainViewBgDarkColor;

// Main border color
+ (NSColor *)mainBorderLightColor;
+ (NSColor *)mainBorderDarkColor;

// Query view background color
+ (NSColor *)queryViewBgLightColor;
+ (NSColor *)queryViewBgDarkColor;

// Query text color
+ (NSColor *)queryTextLightColor;
+ (NSColor *)queryTextDarkColor;

// Result text color
+ (NSColor *)resultTextLightColor;
+ (NSColor *)resultTextDarkColor;

// Result view top bar color
+ (NSColor *)titleBarBgLightColor;
+ (NSColor *)titleBarBgDarkColor;

// Result view background color
+ (NSColor *)resultViewBgLightColor;
+ (NSColor *)resultViewBgDarkColor;

// Button hover color
+ (NSColor *)buttonHoverLightColor;
+ (NSColor *)buttonHoverDarkColor;

// Image tint color
+ (NSColor *)imageTintLightColor;
+ (NSColor *)imageTintDarkColor;

+ (NSColor *)imageTintBlueColor;

@end

NS_ASSUME_NONNULL_END
