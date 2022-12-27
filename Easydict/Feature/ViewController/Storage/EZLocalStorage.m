//
//  EZServiceStorage.m
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLocalStorage.h"

static NSString *kServiceInfoStorageKey = @"kServiceInfoStorageKey";
static NSString *kAllServiceTypesKey = @"kAllServiceTypesKey";
static NSString *kAllServices = @"kAllServices";

@interface EZLocalStorage ()

@end

@implementation EZLocalStorage


static EZLocalStorage *_instance;

+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

// init, save all service info
- (void)setup {
    NSArray *allServiceTypes = [EZServiceTypes allServiceTypes];
    for (EZServiceType type in allServiceTypes) {
        EZServiceInfo *serviceInfo = [self serviceInfoWithType:type];
        if (!serviceInfo) {
            serviceInfo = [[EZServiceInfo alloc] init];
            serviceInfo.enabled = YES;
            serviceInfo.enabledQuery = YES;
            [self saveServiceInfo:serviceInfo];
        }
    }
}

- (NSArray<EZServiceType> *)allServiceTypes {
    NSArray *allServiceTypes = [[NSUserDefaults standardUserDefaults] objectForKey:kAllServiceTypesKey];
    if (!allServiceTypes) {
        allServiceTypes = [EZServiceTypes allServiceTypes];
        [[NSUserDefaults standardUserDefaults] setObject:allServiceTypes forKey:kAllServiceTypesKey];
    }
    return allServiceTypes;
}

- (void)setAllServiceTypes:(NSArray<EZServiceType> *)allServiceTypes {
    [[NSUserDefaults standardUserDefaults] setObject:allServiceTypes forKey:kAllServiceTypesKey];
}

- (NSArray<EZQueryService *> *)allServices {
    NSArray *allServices = [EZServiceTypes servicesFromTypes:[self allServiceTypes]];
    for (EZQueryService *service in allServices) {
        EZServiceInfo *serviceInfo = [self serviceInfoWithType:service.serviceType];
        service.enabled = serviceInfo.enabled;
        service.enabledQuery = serviceInfo.enabledQuery;
    }
    return allServices;
}


- (void)setServiceType:(EZServiceType)type enabledQuery:(BOOL)enabledQuery {
    EZServiceInfo *service = [self serviceInfoWithType:type];
    service.enabledQuery = enabledQuery;
    [self saveServiceInfo:service];
}

- (void)saveServiceInfo:(EZServiceInfo *)serviceInfo {
    // ???: if save EZQueryService, mj_JSONData will Dead cycle.
    NSData *data = [serviceInfo mj_JSONData];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self keyForType:serviceInfo.type]];
}

- (void)saveService:(EZQueryService *)service {
    EZServiceInfo *serviceInfo = [EZServiceInfo serviceInfoWithService:service];
    [self saveServiceInfo:serviceInfo];
}

- (EZServiceInfo *)serviceInfoWithType:(EZServiceType)type {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[self keyForType:type]];
    if (data) {
        return [EZServiceInfo mj_objectWithKeyValues:data];
    }
    return nil;
}

- (NSString *)keyForType:(EZServiceType)type {
    return [NSString stringWithFormat:@"%@-%@", kServiceInfoStorageKey, type];
}

@end
