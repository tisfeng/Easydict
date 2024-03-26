//
//  NSObject+EZDarkMode.m
//  Easydict
//
//  Created by tisfeng on 2022/12/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSObject+EZDarkMode.h"

@implementation NSObject (EZDarkMode)

- (BOOL)isDarkMode {
    NSAppearance *apperance = NSApp.effectiveAppearance;
    if (@available(macOS 10.14, *)) {
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    }
    return NO;
}

@end
