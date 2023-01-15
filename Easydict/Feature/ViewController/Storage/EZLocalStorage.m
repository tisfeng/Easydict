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

// init data, save all service info
- (void)setup {
    NSArray *allServiceTypes = [EZServiceTypes allServiceTypes];
    
    NSArray *allWindowTypes = @[ @(EZWindowTypeMini), @(EZWindowTypeFixed), @(EZWindowTypeMain) ];
    for (NSNumber *number in allWindowTypes) {
        EZWindowType windowType = [number integerValue];
        for (EZServiceType type in allServiceTypes) {
            EZServiceInfo *serviceInfo = [self serviceInfoWithType:type windowType:windowType];
            if (!serviceInfo) {
                serviceInfo = [[EZServiceInfo alloc] init];
                serviceInfo.type = type;
                serviceInfo.enabled = YES;
                serviceInfo.enabledQuery = YES;
                [self setServiceInfo:serviceInfo windowType:windowType];
            }
        }
    }
}

- (NSArray<EZServiceType> *)allServiceTypes:(EZWindowType)windowType {
    NSString *allServiceTypesKey = [self serviceTypesKeyOfWindowType:windowType];
    NSArray *allStoredServiceTypes = [[NSUserDefaults standardUserDefaults] objectForKey:allServiceTypesKey];
    if (!allStoredServiceTypes) {
        allStoredServiceTypes = [EZServiceTypes allServiceTypes];
        [[NSUserDefaults standardUserDefaults] setObject:allStoredServiceTypes forKey:allServiceTypesKey];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:allStoredServiceTypes];
        NSArray *allServiceTypes = [EZServiceTypes allServiceTypes];
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
    NSArray *allServices = [EZServiceTypes servicesFromTypes:[self allServiceTypes:windowType]];
    for (EZQueryService *service in allServices) {
        EZServiceInfo *serviceInfo = [self serviceInfoWithType:service.serviceType windowType:windowType];
        service.enabled = serviceInfo.enabled;
        service.enabledQuery = serviceInfo.enabledQuery;
    }
    return allServices;
}

- (void)setServiceInfo:(EZServiceInfo *)serviceInfo windowType:(EZWindowType)windowType {
    // ???: if save EZQueryService, mj_JSONData will Dead cycle.
    NSData *data = [serviceInfo mj_JSONData];
    NSString *serviceInfoKey = [self keyForServiceType:serviceInfo.type windowType:windowType];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:serviceInfoKey];
}
- (EZServiceInfo *)serviceInfoWithType:(EZServiceType)type windowType:(EZWindowType)windowType {
    NSString *serviceInfoKey = [self keyForServiceType:type windowType:windowType];
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:serviceInfoKey];
    if (data) {
        return [EZServiceInfo mj_objectWithKeyValues:data];
    }
    return nil;
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

#pragma mark -

- (NSString *)keyForServiceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType {
    return [NSString stringWithFormat:@"%@-%@-%ld", kServiceInfoStorageKey, serviceType, windowType];
}

- (NSString *)serviceTypesKeyOfWindowType:(EZWindowType)windowType {
    return [NSString stringWithFormat:@"%@-%ld", kAllServiceTypesKey, windowType];
}

@end
