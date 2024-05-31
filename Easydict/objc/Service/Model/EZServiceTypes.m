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
#import "EZBingService.h"
#import "EZAppleDictionary.h"
#import "EZNiuTransTranslate.h"

@interface EZServiceTypes ()

@property (nonatomic, strong) MMOrderedDictionary<EZServiceType, Class> *allServiceDict;

@end

@implementation EZServiceTypes


static EZServiceTypes *_instance;

+ (instancetype)shared {
    @synchronized(self) {
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
                                           EZServiceTypeAppleDictionary, [EZAppleDictionary class],
                                           EZServiceTypeYoudao, [EZYoudaoTranslate class],
                                           EZServiceTypeOpenAI, [EZOpenAIService class],
                                           EZServiceTypeBuiltInAI, [EZBuiltInAIService class],
                                           EZServiceTypeCustomOpenAI, [EZCustomOpenAIService class],
                                           EZServiceTypeDeepL, [EZDeepLTranslate class],
                                           EZServiceTypeGoogle, [EZGoogleTranslate class],
                                           EZServiceTypeApple, [EZAppleService class],
                                           EZServiceTypeBaidu, [EZBaiduTranslate class],
                                           EZServiceTypeBing, [EZBingService class],
                                           EZServiceTypeVolcano, [EZVolcanoTranslate class],
                                           EZServiceTypeNiuTrans, [EZNiuTransTranslate class],
                                           EZServiceTypeCaiyun, [EZCaiyunService class],
                                           EZServiceTypeTencent, [EZTencentService class],
                                           EZServiceTypeAli, [EZAliService class],
                                           EZServiceTypeGemini, [EZGeminiService class],
                                           nil];
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
        // Maybe OpenAI has been disabled.
        if (service) {
            [services addObject:service];
        }
    }
    return services;
}

@end
