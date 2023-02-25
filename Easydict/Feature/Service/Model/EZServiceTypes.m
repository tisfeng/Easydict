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
#import "EZDeppLTranslate.h"
#import "EZVolcanoTranslate.h"
#import "EZAppleService.h"

@implementation EZServiceTypes

+ (NSArray<EZServiceType> *)allServiceTypes {
    return [[self allServiceDict] sortedKeys];
}

+ (MMOrderedDictionary<EZServiceType, Class> *)allServiceDict {
    MMOrderedDictionary *orderDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                      //  EZServiceTypeOpenAI, [EZOpenAIService class],
                                      EZServiceTypeApple, [EZAppleService class],
                                      EZServiceTypeYoudao, [EZYoudaoTranslate class],
                                      EZServiceTypeDeepL, [EZDeppLTranslate class],
                                      EZServiceTypeGoogle, [EZGoogleTranslate class],
                                      EZServiceTypeBaidu, [EZBaiduTranslate class],
                                      EZServiceTypeVolcano, [EZVolcanoTranslate class],
                                      nil];
    
    NSString *newFeature = [[NSUserDefaults standardUserDefaults] stringForKey:EZNewFeatureKey];
    if ([newFeature isEqualToString:@"1"]) {
        [orderDict setObject:[EZOpenAIService class] forKey:EZServiceTypeOpenAI];
    }
    
    return orderDict;
}

+ (EZQueryService *)serviceWithType:(EZServiceType)type {
    Class Cls = [[self allServiceDict] objectForKey:type];
    return [Cls new];
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
