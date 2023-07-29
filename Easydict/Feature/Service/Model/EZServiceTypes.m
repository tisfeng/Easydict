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
#import "EZConfiguration.h"
#import "EZAppleDictionary.h"

@interface EZServiceTypes ()

@property (nonatomic, strong) MMOrderedDictionary<EZServiceType, Class> *allServiceDict;

@end

@implementation EZServiceTypes


static EZServiceTypes *_instance;

+ (instancetype)shared {
    @synchronized (self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
        }
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

- (NSArray<EZServiceType> *)allServiceTypes {
    return [[self allServiceDict] sortedKeys];
}

- (MMOrderedDictionary<EZServiceType, Class> *)allServiceDict {
    MMOrderedDictionary *allServiceDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                       //  EZServiceTypeOpenAI, [EZOpenAIService class],
                       EZServiceTypeYoudao, [EZYoudaoTranslate class],
                       EZServiceTypeAppleDictionary,  [EZAppleDictionary class],
                       EZServiceTypeDeepL, [EZDeepLTranslate class],
                       EZServiceTypeGoogle, [EZGoogleTranslate class],
                       EZServiceTypeApple, [EZAppleService class],
                       EZServiceTypeBaidu, [EZBaiduTranslate class],
                       EZServiceTypeVolcano, [EZVolcanoTranslate class],
                       nil];
    if ([EZConfiguration.shared isBeta]) {
        [allServiceDict insertObject:[EZOpenAIService class] forKey:EZServiceTypeOpenAI atIndex:0];
    }
    return allServiceDict;
}


- (nullable EZQueryService *)serviceWithType:(EZServiceType)type {
    Class Cls = [[self allServiceDict] objectForKey:type];
    return [Cls new];
}

- (NSArray<EZQueryService *> *)servicesFromTypes:(NSArray<EZServiceType> *)types {
    NSMutableArray *services = [NSMutableArray array];
    for (EZServiceType type in types) {
        EZQueryService *service = [self serviceWithType:type];
        // May be OpenAI has been disabled.
        if (service) {
            [services addObject:service];
        }
    }
    return services;
}

@end
