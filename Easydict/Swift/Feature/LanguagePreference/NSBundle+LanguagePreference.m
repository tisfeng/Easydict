//
//  NSBundle+LanguagePreference.m
//  Easydict
//
//  Created by choykarl on 2024/3/23.
//  Copyright © 2024 izual. All rights reserved.
//

#import <objc/runtime.h>

@implementation NSBundle (LanguagePreference)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass([NSBundle mainBundle], [EZLocalizedBundle class]);
    });
}

@end
