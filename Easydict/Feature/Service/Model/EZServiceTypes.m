//
//  TranslateTypeMap.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceTypes.h"
#import "EZGoogleTranslate.h"
#import "EZBaiduTranslate.h"
#import "EZYoudaoTranslate.h"
#import "EZDeppLTranslate.h"
#import "EZVolcanoTranslate.h"

@implementation EZServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self allServiceDict] allKeys];
}

+ (NSDictionary<EZServiceType, Class> *)allServiceDict {
    NSDictionary *dict = @{
        EZServiceTypeGoogle : [EZGoogleTranslate class],
        EZServiceTypeBaidu : [EZBaiduTranslate class],
        EZServiceTypeYoudao : [EZYoudaoTranslate class],
        EZServiceTypeDeepL : [EZDeppLTranslate class],
        EZServiceTypeVolcano : [EZVolcanoTranslate class],
    };
    return dict;
}

+ (EZQueryService *)serviceWithType:(EZServiceType)type {
    Class Cls = [[self allServiceDict] objectForKey:type];
    return [Cls new];
}

+ (NSArray<EZQueryService *> *)allServices {
    NSArray *allServiceTypes = [self allServiceTypes];
    NSMutableArray *services = [NSMutableArray array];
    for (EZServiceType type in allServiceTypes) {
        EZQueryService *service = [EZServiceTypes serviceWithType:type];
        [services addObject:service];
    }
    return services;
}

+ (NSArray<EZQueryService *> *)servicesFromTypes:(NSArray<EZServiceType> *)types {
    NSMutableArray *services = [NSMutableArray array];
    for (EZServiceType type in types) {
        EZQueryService *service = [EZServiceTypes serviceWithType:type];
        [services addObject:service];
    }
    return services;
}

@end
