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

@implementation EZServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self allServiceDict] sortedKeys];
}

+ (MMOrderedDictionary<EZServiceType, Class> *)allServiceDict {
    MMOrderedDictionary *orderDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                      //  EZServiceTypeOpenAI, [EZOpenAIService class],
                                      EZServiceTypeApple, [EZAppleService class],
                                      EZServiceTypeYoudao, [EZYoudaoTranslate class],
                                      EZServiceTypeDeepL, [EZDeepLTranslate class],
                                      EZServiceTypeGoogle, [EZGoogleTranslate class],
                                      EZServiceTypeBaidu, [EZBaiduTranslate class],
                                      EZServiceTypeVolcano, [EZVolcanoTranslate class],
                                      nil];
    
    NSString *betaFeatureKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZBetaFeatureKey];
    if ([betaFeatureKey isEqualToString:@"1"]) {
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
