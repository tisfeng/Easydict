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

+ (NSArray<EDServiceType> *)allServiceTypes {
    return [[self serviceDict] allKeys];
}

+ (NSDictionary<EDServiceType, TranslateService *> *)serviceDict {
    NSDictionary *dict = @{
        EDServiceTypeGoogle : GoogleTranslate.new,
        EDServiceTypeBaidu : BaiduTranslate.new,
        EDServiceTypeYoudao : YoudaoTranslate.new
    };
    return dict;
}

+ (TranslateService *)serviceWithType:(EDServiceType)type {
    return [self serviceDict][type];
}

@end
