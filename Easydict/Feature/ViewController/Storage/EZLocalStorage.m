//
//  EZServiceStorage.m
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLocalStorage.h"
#import "EZLog.h"

static NSString *const kServiceInfoStorageKey = @"kServiceInfoStorageKey";
static NSString *const kAllServiceTypesKey = @"kAllServiceTypesKey";
static NSString *const kQueryCountKey = @"kQueryCountKey";
static NSString *const kQueryCharacterCountKey = @"kQueryCharacterCountKey";

static NSString *const kAppModelTriggerListKey = @"kAppModelTriggerListKey";

@interface EZLocalStorage ()

@end

@implementation EZLocalStorage

// TODO: need to optimize, this code is so ugly.

static EZLocalStorage *_instance;

+ (instancetype)shared {
    @synchronized(self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
            [_instance setup];
        }
    }
    return _instance;
}

+ (void)destroySharedInstance {
    _instance = nil;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

// Init data, save all service info
- (void)setup {
    NSArray *allServiceTypes = [EZServiceTypes.shared allServiceTypes];

    NSArray *allWindowTypes = @[ @(EZWindowTypeMini), @(EZWindowTypeFixed), @(EZWindowTypeMain) ];
    for (NSNumber *number in allWindowTypes) {
        EZWindowType windowType = [number integerValue];
        for (EZServiceType serviceType in allServiceTypes) {
            EZServiceInfo *serviceInfo = [self serviceInfoWithType:serviceType windowType:windowType];
            if (!serviceInfo) {
                serviceInfo = [[EZServiceInfo alloc] init];
                serviceInfo.type = serviceType;
                serviceInfo.enabled = YES;

                // Mini type should keep concise.
                if (windowType == EZWindowTypeMini) {
                    NSArray *defaultEnabledServices = @[
                        EZServiceTypeOpenAI,
                        EZServiceTypeDeepL,
                        EZServiceTypeYoudao,
                        EZServiceTypeGoogle,
                    ];
                    serviceInfo.enabled = [defaultEnabledServices containsObject:serviceType];
                }

                // There is a very small probability that Volcano webView translator will crash.
                if (serviceType != EZServiceTypeVolcano) {
                    serviceInfo.enabledQuery = YES;
                }
                [self setServiceInfo:serviceInfo windowType:windowType];
            }
        }
    }
}

- (NSArray<EZServiceType> *)allServiceTypes:(EZWindowType)windowType {
    NSString *allServiceTypesKey = [self serviceTypesKeyOfWindowType:windowType];
    NSArray *allServiceTypes = EZServiceTypes.shared.allServiceTypes;
    
    NSArray *allStoredServiceTypes = [[NSUserDefaults standardUserDefaults] objectForKey:allServiceTypesKey];
    if (!allStoredServiceTypes) {
        allStoredServiceTypes = allServiceTypes;
        [[NSUserDefaults standardUserDefaults] setObject:allStoredServiceTypes forKey:allServiceTypesKey];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:allStoredServiceTypes];
        if (allStoredServiceTypes.count != allServiceTypes.count) {
            for (EZServiceType type in allServiceTypes) {
                if ([allStoredServiceTypes indexOfObject:type] == NSNotFound) {
                    [array insertObject:type atIndex:0];
                }
            }
        }
        allStoredServiceTypes = [array copy];
    }

    return allStoredServiceTypes;
}
- (void)setAllServiceTypes:(NSArray<EZServiceType> *)allServiceTypes windowType:(EZWindowType)windowType {
    NSString *allServiceTypesKey = [self serviceTypesKeyOfWindowType:windowType];
    [[NSUserDefaults standardUserDefaults] setObject:allServiceTypes forKey:allServiceTypesKey];
}

- (NSArray<EZQueryService *> *)allServices:(EZWindowType)windowType {
    NSArray *allServices = [EZServiceTypes.shared servicesFromTypes:[self allServiceTypes:windowType]];
    for (EZQueryService *service in allServices) {
        EZServiceInfo *serviceInfo = [self serviceInfoWithType:service.serviceType windowType:windowType];
        BOOL enabled = YES;
        BOOL enabledQuery = YES;
        if (serviceInfo) {
            enabled = serviceInfo.enabled;
            enabledQuery = serviceInfo.enabledQuery;
        }
        service.enabled = enabled;
        service.enabledQuery = enabledQuery;
    }
    return allServices;
}

- (void)setServiceInfo:(EZServiceInfo *)serviceInfo windowType:(EZWindowType)windowType {
    // ???: if save EZQueryService, mj_JSONData will dead cycle.
    NSData *data = [serviceInfo mj_JSONData];
    NSString *serviceInfoKey = [self keyForServiceType:serviceInfo.type windowType:windowType];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:serviceInfoKey];
}
- (nullable EZServiceInfo *)serviceInfoWithType:(EZServiceType)type windowType:(EZWindowType)windowType {
    NSString *serviceInfoKey = [self keyForServiceType:type windowType:windowType];
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:serviceInfoKey];

    EZServiceInfo *serviceInfo = nil;
    if (data) {
        serviceInfo = [EZServiceInfo mj_objectWithKeyValues:data];
    }

    return serviceInfo;
}

- (void)setService:(EZQueryService *)service windowType:(EZWindowType)windowType {
    EZServiceInfo *serviceInfo = [EZServiceInfo serviceInfoWithService:service];
    [self setServiceInfo:serviceInfo windowType:windowType];
}

- (void)setEnabledQuery:(BOOL)enabledQuery serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType {
    EZServiceInfo *service = [self serviceInfoWithType:serviceType windowType:windowType];
    service.enabledQuery = enabledQuery;
    [self setServiceInfo:service windowType:windowType];
}

#pragma mark - Query count

- (void)increaseQueryCount:(NSString *)queryText {
    NSInteger count = [self queryCount];
    NSInteger level = [self queryLevel:count];
    count++;
    NSInteger newLevel = [self queryLevel:count];
    if (count == 1 || newLevel != level) {
        NSString *levelTitle = [self queryLevelTitle:newLevel chineseFlag:YES];
        NSLog(@"new level: %@", levelTitle);

        NSDictionary *dict = @{
            @"count" : [NSString stringWithFormat:@"%ld", count],
            @"level" : [NSString stringWithFormat:@"%ld", newLevel],
            @"title" : levelTitle,
        };
        [EZLog logEventWithName:@"query_count" parameters:dict];
    }

    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kQueryCountKey];

    NSInteger queryCharacterCount = [self queryCharacterCount];
    queryCharacterCount += queryText.length;
    [self saveQueryCharacterCount:queryCharacterCount];
}

- (NSInteger)queryCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kQueryCountKey];
}

- (void)resetQueryCount {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kQueryCountKey];
}

#pragma mark - Query character count

- (void)saveQueryCharacterCount:(NSInteger)count {
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kQueryCharacterCountKey];
}

- (NSInteger)queryCharacterCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kQueryCharacterCountKey];
}

#pragma mark -

/**
query count  | level | title
0-10         | 1     | 黑铁 Iron
10-100       | 2     | 青铜 Bronze
100-500      | 3     | 白银 Silver
500-2000     | 4     | 黄金 Gold
2000-5000    | 5     | 铂金 Platinum
5000-10000   | 6     | 钻石 Diamond
10000-20000  | 7     | 大师 Master
20000-50000  | 8     | 宗师 Grandmaster
50000-100000 | 9     | 王者 King
100000-∞     | 10    | 传奇 Legend
*/

- (NSInteger)queryLevel:(NSInteger)count {
    if (count < 10) {
        return 1;
    } else if (count < 100) {
        return 2;
    } else if (count < 500) {
        return 3;
    } else if (count < 2000) {
        return 4;
    } else if (count < 5000) {
        return 5;
    } else if (count < 10000) {
        return 6;
    } else if (count < 20000) {
        return 7;
    } else if (count < 50000) {
        return 8;
    } else if (count < 100000) {
        return 9;
    } else {
        return 10;
    }
}

- (NSString *)queryLevelTitle:(NSInteger)level chineseFlag:(BOOL)chineseFlag {
    NSString *title = nil;
    NSArray *titles = @[ @"黑铁", @"青铜", @"白银", @"黄金", @"铂金", @"钻石", @"大师", @"宗师", @"王者", @"传奇" ];
    NSArray *enTitles = @[ @"Iron", @"Bronze", @"Silver", @"Gold", @"Platinum", @"Diamond", @"Master", @"Grandmaster", @"King", @"Legend" ];

    level = MAX(level, 1);
    level = MIN(level, titles.count);

    if (chineseFlag) {
        title = titles[level - 1];
    } else {
        title = enTitles[level - 1];
    }

    return title;
}

#pragma mark - Service type key

- (NSString *)keyForServiceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType {
    return [NSString stringWithFormat:@"%@-%@-%ld", kServiceInfoStorageKey, serviceType, windowType];
}

- (NSString *)serviceTypesKeyOfWindowType:(EZWindowType)windowType {
    return [NSString stringWithFormat:@"%@-%ld", kAllServiceTypesKey, windowType];
}

#pragma mark - Disabled AppModel

- (void)setSelectTextTypeAppModelList:(NSArray<EZAppModel *> *)selectTextAppModelList {
    NSArray *dictArray = [EZAppModel mj_keyValuesArrayWithObjectArray:selectTextAppModelList];
    [[NSUserDefaults standardUserDefaults] setObject:dictArray forKey:kAppModelTriggerListKey];
}

- (NSArray<EZAppModel *> *)selectTextTypeAppModelList {
    NSArray *dictArray = [[NSUserDefaults standardUserDefaults] valueForKey:kAppModelTriggerListKey];
    NSArray *appModels = [EZAppModel mj_objectArrayWithKeyValuesArray:dictArray] ?: [NSArray array];
    
    if (!dictArray) {
        EZAppModel *keyChainApp = [[EZAppModel alloc] init];
        keyChainApp.appBundleID = @"com.apple.keychainaccess";
        keyChainApp.triggerType = EZTriggerTypeNone;
        appModels = @[
            keyChainApp,
        ];
    }
    
    return appModels;
}

@end
