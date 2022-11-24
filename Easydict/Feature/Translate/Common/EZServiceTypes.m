//
//  TranslateTypeMap.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZServiceTypes.h"
#import "GoogleTranslate.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"

@implementation EZServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self serviceDict] allKeys];
}

+ (NSDictionary<EZServiceType, Class> *)serviceDict {
    NSDictionary *dict = @{
        EZServiceTypeGoogle : [GoogleTranslate class],
        EZServiceTypeBaidu : [BaiduTranslate class],
        EZServiceTypeYoudao : [YoudaoTranslate class]
    };
    return dict;
}

+ (TranslateService *)serviceWithType:(EZServiceType)type {
    Class Cls = [[self serviceDict] objectForKey:type];
    return [Cls new];
}

@end
