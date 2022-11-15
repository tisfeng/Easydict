//
//  TranslateTypeMap.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "ServiceTypes.h"
#import "GoogleTranslate.h"
#import "BaiduTranslate.h"
#import "YoudaoTranslate.h"

@implementation ServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self serviceDict] allKeys];
}

+ (NSDictionary<EZServiceType, TranslateService *> *)serviceDict {
    NSDictionary *dict = @{
        EZServiceTypeGoogle : GoogleTranslate.new,
        EZServiceTypeBaidu : BaiduTranslate.new,
        EZServiceTypeYoudao : YoudaoTranslate.new
    };
    return dict;
}

+ (TranslateService *)serviceWithType:(EZServiceType)type {
    return [self serviceDict][type];
}

@end
