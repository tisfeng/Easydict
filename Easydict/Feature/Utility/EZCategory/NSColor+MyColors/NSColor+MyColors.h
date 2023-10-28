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

+ (NSColor *)ez_dynamicColorLight:(NSColor *)light dark:(NSColor *)dark;

/// Main background color
+ (NSColor *)ez_mainViewBgColor;

/// Main border color
+ (NSColor *)ez_mainBorderColor;

/// Query view background color
+ (NSColor *)ez_queryViewBgColor;

/// Query text color
+ (NSColor *)ez_queryTextColor;

/// Result text color
+ (NSColor *)ez_resultTextColor;
/// Light result text color used for CSS support
///
/// ``UIKit.UIColor`` and ``SwiftUI.Color`` can resolve to a given environment.
///  But there is no such API in NSColor publicly.
+ (NSColor *)ez_resultTextLightColor;
/// Dark result text color used for CSS support
///
/// ``UIKit.UIColor`` and ``SwiftUI.Color`` can resolve to a given environment.
///  But there is no such API in NSColor publicly.
+ (NSColor *)ez_resultTextDarkColor;

/// Result view background color
+ (NSColor *)ez_resultViewBgColor;
/// Light result view background color used for CSS support
///
/// ``UIKit.UIColor`` and ``SwiftUI.Color`` can resolve to a given environment.
///  But there is no such API in NSColor publicly.
+ (NSColor *)ez_resultViewBgLightColor;
/// Dark result view background color used for CSS support
///
/// ``UIKit.UIColor`` and ``SwiftUI.Color`` can resolve to a given environment.
///  But there is no such API in NSColor publicly.
+ (NSColor *)ez_resultViewBgDarkColor;

/// Result view top bar color
+ (NSColor *)ez_titleBarBgColor;

/// Button hover color
+ (NSColor *)ez_buttonHoverColor;

/// Image tint color
+ (NSColor *)ez_imageTintColor;

+ (NSColor *)ez_imageTintBlueColor;

+ (NSColor *)ez_blueTitleColor;

+ (NSColor *)ez_tableRowViewBgColor;

@end

NS_ASSUME_NONNULL_END
