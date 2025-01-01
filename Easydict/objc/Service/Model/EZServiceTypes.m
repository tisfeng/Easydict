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
#import "EZAppleService.h"
#import "EZBingService.h"
#import "EZAppleDictionary.h"
#import "EZNiuTransTranslate.h"
#import "Easydict-Swift.h"

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
                                           EZServiceTypeYoudao, [EZYoudaoService class],
                                           EZServiceTypeOpenAI, [EZOpenAIService class],
                                           EZServiceTypeBuiltInAI, [EZBuiltInAIService class],
                                           EZServiceTypeGemini, [EZGeminiService class],
                                           EZServiceTypeOllama, [EZOllamaService class],
                                           EZServiceTypePolishing, [EZPolishingService class],
                                           EZServiceTypeSummary, [EZSummaryService class],
                                           EZServiceTypeCustomOpenAI, [EZCustomOpenAIService class],
                                           EZServiceTypeDeepL, [EZDeepLTranslate class],
                                           EZServiceTypeGoogle, [EZGoogleTranslate class],
                                           EZServiceTypeApple, [EZAppleService class],
                                           EZServiceTypeBaidu, [EZBaiduTranslate class],
                                           EZServiceTypeBing, [EZBingService class],
                                           EZServiceTypeVolcano, [EZVolcanoService class],
                                           EZServiceTypeNiuTrans, [EZNiuTransTranslate class],
                                           EZServiceTypeCaiyun, [EZCaiyunService class],
                                           EZServiceTypeTencent, [EZTencentService class],
                                           EZServiceTypeAlibaba, [EZAliService class],
                                           nil];
    return allServiceDict;
}

// pass service type with id format like `EZServiceTypeCustomOpenAI#UUID` to support multi instances
- (nullable EZQueryService *)serviceWithTypeId:(NSString *)typeIdIfHave {
    NSString *type = typeIdIfHave;
    NSString *uuid = @"";
    if ([typeIdIfHave containsString:@"#"]) {
        NSArray *items = [typeIdIfHave componentsSeparatedByString:@"#"];
        type = items[0];
        uuid = items[1];
    }
    Class Cls = [[self allServiceDict] objectForKey:type];
    EZQueryService *service = [Cls new];
    service.uuid = uuid;
    return service;
}


- (NSArray<EZQueryService *> *)servicesFromTypes:(NSArray<NSString *> *)types {
    NSMutableArray *services = [NSMutableArray array];
    for (NSString *serviceType in types) {
        EZQueryService *service = [self serviceWithTypeId:serviceType];
        // Maybe OpenAI has been disabled.
        if (service) {
            [services addObject:service];
        }
    }
    return services;
}

@end
