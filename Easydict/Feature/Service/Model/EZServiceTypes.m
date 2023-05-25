//
//  TranslateTypeMap.m
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceTypes.h"
#import "EZGoogleTranslate.h"
#import "EZBaiduTranslate.h"
#import "EZYoudaoTranslate.h"
#import "EZDeepLTranslate.h"
#import "EZVolcanoTranslate.h"
#import "EZAppleService.h"
#import "EZOpenAIService.h"
#import "NSUserDefaults+EZConfig.h"

@implementation EZServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self allServiceDict] sortedKeys];
}

+ (MMOrderedDictionary<EZServiceType, Class> *)allServiceDict {
    MMOrderedDictionary *orderDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                      //  EZServiceTypeOpenAI, [EZOpenAIService class],
                                      EZServiceTypeDeepL, [EZDeepLTranslate class],
                                      EZServiceTypeYoudao, [EZYoudaoTranslate class],
                                      EZServiceTypeApple, [EZAppleService class],
                                      EZServiceTypeGoogle, [EZGoogleTranslate class],
                                      EZServiceTypeBaidu, [EZBaiduTranslate class],
                                      EZServiceTypeVolcano, [EZVolcanoTranslate class],
                                      nil];
    
    BOOL isBeta = [[NSUserDefaults standardUserDefaults] isBeta];
    if (isBeta) {
        [orderDict setObject:[EZOpenAIService class] forKey:EZServiceTypeOpenAI];
    }
    
    return orderDict;
}

+ (nullable EZQueryService *)serviceWithType:(EZServiceType)type {
    Class Cls = [[self allServiceDict] objectForKey:type];
    return [Cls new];
}

+ (NSArray<EZQueryService *> *)servicesFromTypes:(NSArray<EZServiceType> *)types {
    NSMutableArray *services = [NSMutableArray array];
    for (EZServiceType type in types) {
        EZQueryService *service = [EZServiceTypes serviceWithType:type];
        // May be OpenAI has been disabled.
        if (service) {
            [services addObject:service];
        }
    }
    return services;
}

@end
