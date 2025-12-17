//
//  EZServiceStorage.m
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLocalStorage.h"
#import "EZLog.h"
#import "Easydict-Swift.h"

static NSString *const kServiceInfoStorageKey = @"kServiceInfoStorageKey";
static NSString *const kAllServiceTypesKey = @"kAllServiceTypesKey";
static NSString *const kQueryCountKey = @"kQueryCountKey";
static NSString *const kQueryCharacterCountKey = @"kQueryCharacterCountKey";

static NSString *const kAppModelTriggerListKey = @"kAppModelTriggerListKey";

static NSString *const kQueryServiceRecordKey = @"kQueryServiceRecordKey";

static NSInteger const kTotalUserCount = 1000;

@interface EZLocalStorage ()

@property (nonatomic, assign) NSInteger queryCount;
@property (nonatomic, assign) NSInteger queryCharacterCount;
@property (nonatomic, copy) NSDictionary *queryServiceRecordDict;

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

    NSArray *allWindowTypes = @[ @(EZWindowTypeMini), @(EZWindowTypeFixed), @(EZWindowTypeMain) ];
    for (NSNumber *number in allWindowTypes) {
        EZWindowType windowType = [number integerValue];
        NSArray<NSString *> *allServiceTypes = [self allServiceTypes:windowType];
        
        for (NSString *serviceType in allServiceTypes) {
            NSString *type = @"";
            NSString *uuid = @"";
            if ([serviceType containsString:@"#"]) {
                NSArray *serivceTypeId = [serviceType componentsSeparatedByString:@"#"];
                type = serivceTypeId[0];
                uuid = serivceTypeId[1];
            } else {
                type = serviceType;
            }
            
            EZServiceInfo *serviceInfo = [self serviceInfoWithType:type serviceId:uuid windowType:windowType];
            
            // New service.
            if (!serviceInfo) {
                serviceInfo = [[EZServiceInfo alloc] init];
                serviceInfo.type = serviceType;
                serviceInfo.enabled = YES;
                serviceInfo.enabledQuery = YES;
                serviceInfo.uuid = uuid;

                /**
                 Fix https://github.com/tisfeng/Easydict/issues/269 and https://github.com/tisfeng/Easydict/issues/372

                 If there is a new service, we enable it but disable auto query, and add it to the end of the array.
                 
                 If it is the user's first time, auto query should be all allowed.
                 */
                if (self.queryCount > 0) {
                    serviceInfo.enabledQuery = NO;
                }

                // Apply consistent default enabled services for all window types
                NSArray *defaultEnabledServices = @[
                    EZServiceTypeAppleDictionary,
                    EZServiceTypeYoudao,
                    EZServiceTypeDeepL,
                    EZServiceTypeGoogle,
                    EZServiceTypeBuiltInAI,
                ];
                serviceInfo.enabled = [defaultEnabledServices containsObject:serviceType];

                [self setServiceInfo:serviceInfo windowType:windowType];
            }
        }
    }
}

- (NSArray<NSString *> *)allServiceTypes:(EZWindowType)windowType {
    NSString *allServiceTypesKey = [self serviceTypesKeyOfWindowType:windowType];
    NSArray *allServiceTypes = EZServiceTypes.shared.allServiceTypes;
    NSArray *allStoredServiceTypes = [[NSUserDefaults standardUserDefaults] objectForKey:allServiceTypesKey];
    if (!allStoredServiceTypes) {
        allStoredServiceTypes = allServiceTypes;
        [[NSUserDefaults standardUserDefaults] setObject:allStoredServiceTypes forKey:allServiceTypesKey];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:allStoredServiceTypes];
        if (![allStoredServiceTypes isEqualToArray:allServiceTypes]) {
            for (EZServiceType type in allServiceTypes) {
                if ([allStoredServiceTypes indexOfObject:type] == NSNotFound) {
                    [array addObject:type];
                }
            }
        }
        allStoredServiceTypes = [array copy];
    }
    return allStoredServiceTypes;
}

- (void)setAllServiceTypes:(NSArray<NSString *> *)allServiceTypes windowType:(EZWindowType)windowType {
    NSString *allServiceTypesKey = [self serviceTypesKeyOfWindowType:windowType];
    [[NSUserDefaults standardUserDefaults] setObject:allServiceTypes forKey:allServiceTypesKey];
}

- (NSArray<EZQueryService *> *)allServices:(EZWindowType)windowType {
    NSArray *allServices = [EZServiceTypes.shared servicesFromTypes:[self allServiceTypes:windowType]];
    for (EZQueryService *service in allServices) {
        [self updateServiceInfo:service windowType:windowType];
    }
    return allServices;
}

- (EZQueryService *)service:(NSString *)serviceTypeId windowType:(EZWindowType)windowType {
    EZQueryService *service = [EZServiceTypes.shared serviceWithTypeId:serviceTypeId];
    [self updateServiceInfo:service windowType:windowType];
    return service;
}

- (void)updateServiceInfo:(EZQueryService *)service windowType:(EZWindowType)windowType {
    EZServiceInfo *serviceInfo = [self serviceInfoWithType:service.serviceType serviceId:service.uuid windowType:windowType];
    BOOL enabled = YES;
    BOOL enabledQuery = YES;
    NSString *uuid = @"";
    if (serviceInfo) {
        enabled = serviceInfo.enabled;
        enabledQuery = serviceInfo.enabledQuery;
        uuid = serviceInfo.uuid;
    }
    // update id
    service.uuid = uuid;
    service.enabled = enabled;
    service.enabledQuery = enabledQuery;
    service.windowType = windowType;
}

- (void)setServiceInfo:(EZServiceInfo *)serviceInfo windowType:(EZWindowType)windowType {
    // ???: if save EZQueryService, mj_JSONData will dead cycle.
    NSData *data = [serviceInfo mj_JSONData];
    NSString *serviceInfoKey = [self keyForServiceType:serviceInfo.type serviceId:serviceInfo.uuid windowType:windowType];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:serviceInfoKey];
}

- (nullable EZServiceInfo *)serviceInfoWithType:(EZServiceType)type serviceId:(NSString *)serviceId windowType:(EZWindowType)windowType {
    NSString *serviceInfoKey = [self keyForServiceType:type serviceId:serviceId windowType:windowType];
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

- (void)setEnabledQuery:(BOOL)enabledQuery serviceType:(EZServiceType)serviceType serviceId:(NSString *)serviceId windowType:(EZWindowType)windowType {
    EZServiceInfo *service = [self serviceInfoWithType:serviceType serviceId:serviceId windowType:windowType];
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
        MMLogInfo(@"new level: %@", levelTitle);

        NSDictionary *dict = @{
            @"count" : [NSString stringWithFormat:@"%ld", count],
            @"level" : [NSString stringWithFormat:@"%ld", newLevel],
            @"title" : levelTitle,
        };
        [EZLog logEventWithName:@"query_count" parameters:dict];
    }

    self.queryCount = count;

    NSInteger queryCharacterCount = [self queryCharacterCount];
    queryCharacterCount += queryText.length;
    self.queryCharacterCount = queryCharacterCount;
}

- (void)increaseQueryService:(EZQueryService *)service {
    EZServiceType serviceType = service.serviceType;
    EZQueryServiceRecord *serviceRecord = [self recordWithServiceType:serviceType];;
    serviceRecord.queryCount += 1;
    serviceRecord.queryCharacterCount += service.queryModel.queryText.length;
    [self setQueryServiceRecord:serviceRecord serviceType:serviceType];

    [EZLog logQueryService:service];
}

- (BOOL)hasFreeQuotaLeft:(EZQueryService *)service {
    EZQueryServiceRecord *record = [self recordWithServiceType:service.serviceType];
    /**
     例如腾讯翻译每月有500万免费字符，假如当前有1000个用户，则每人可以使用字符数为：500万/1000 = 5千
     */
    CGFloat freeCount = [service totalFreeQueryCharacterCount] * 0.9 / kTotalUserCount;
    return record.queryCharacterCount < freeCount;
}

/// New user means query count<100
- (BOOL)isNewUser {
    return self.queryCount < 100;
}

#pragma mark - Query character count

- (void)setQueryCharacterCount:(NSInteger)count {
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kQueryCharacterCountKey];
}

- (NSInteger)queryCharacterCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kQueryCharacterCountKey];
}

#pragma mark - Query count

- (NSInteger)queryCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kQueryCountKey];
}

- (void)setQueryCount:(NSInteger)queryCount {
    [[NSUserDefaults standardUserDefaults] setInteger:queryCount forKey:kQueryCountKey];
}

#pragma mark - Query service count

- (EZQueryServiceRecord *)recordWithServiceType:(EZServiceType)serviceType {
    NSMutableDictionary *mdict = [self.queryServiceRecordDict mutableCopy];
    if (!mdict) {
        mdict = [NSMutableDictionary dictionary];
    }

    EZQueryServiceRecord *record = [EZQueryServiceRecord mj_objectWithKeyValues:mdict[serviceType]];
    if (!record) {
        record = [[EZQueryServiceRecord alloc] initWithServiceType:serviceType queryCount:0 queryCharacterCount:0];
        [self setQueryServiceRecord:record serviceType:serviceType];
    }
    
    return record;
}

- (void)setQueryServiceRecord:(EZQueryServiceRecord *)record serviceType:(EZServiceType)serviceType {
    NSMutableDictionary *mdict = [self.queryServiceRecordDict mutableCopy];
    if (!mdict) {
        mdict = [NSMutableDictionary dictionary];
    }
    mdict[serviceType] = [record mj_keyValues];
    self.queryServiceRecordDict = mdict;
}

- (NSDictionary *)queryServiceRecordDict {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kQueryServiceRecordKey];
    return dict;
}

- (void)setQueryServiceRecordDict:(NSDictionary *)queryServiceRecordDict {
    [[NSUserDefaults standardUserDefaults] setObject:queryServiceRecordDict forKey:kQueryServiceRecordKey];
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

- (NSString *)keyForServiceType:(EZServiceType)serviceType serviceId: (NSString *)serviceId windowType:(EZWindowType)windowType {
    if (!serviceId || [serviceId isEqual:@""]) {
        return [NSString stringWithFormat:@"%@-%@-%ld", kServiceInfoStorageKey, serviceType, windowType];
    }
    return [NSString stringWithFormat:@"%@-%@-%@-%ld", kServiceInfoStorageKey, serviceType, serviceId, windowType];
}

- (NSString *)serviceTypesKeyOfWindowType:(EZWindowType)windowType {
    return [NSString stringWithFormat:@"%@-%ld", kAllServiceTypesKey, windowType];
}

#pragma mark - Disabled AppModel

- (void)setSelectTextTypeAppModelList:(NSArray<EZAppModel *> *)selectTextAppModelList {
    NSArray<NSDictionary *> *dictArray = [EZAppModel dictionaryArrayFromAppModels:selectTextAppModelList];
    [[NSUserDefaults standardUserDefaults] setObject:dictArray forKey:kAppModelTriggerListKey];
}

- (NSArray<EZAppModel *> *)selectTextTypeAppModelList {
    NSArray<NSDictionary *> *dictArray = [[NSUserDefaults standardUserDefaults] valueForKey:kAppModelTriggerListKey];
    NSArray<EZAppModel *> *appModels = [EZAppModel appModelsFromDictionaryArray:dictArray ?: @[]];
    
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
