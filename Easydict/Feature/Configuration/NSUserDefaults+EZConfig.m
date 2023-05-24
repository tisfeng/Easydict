//
//  NSUserDefaults+EZConfig.m
//  Easydict
//
//  Created by tisfeng on 2023/5/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSUserDefaults+EZConfig.h"

@implementation NSUserDefaults (EZConfig)

- (BOOL)isBeta {
    BOOL isBeta = [[[NSUserDefaults standardUserDefaults] stringForKey:EZBetaFeatureKey] boolValue];
    return isBeta;
}

@end
