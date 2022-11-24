//
//  EZServiceStorage.m
//  Open Bob
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceStorage.h"

static NSString *kServiceInfoStorageKey = @"kServiceInfoStorageKey";

@interface EZServiceStorage ()

@end

@implementation EZServiceStorage


static EZServiceStorage *_instance;

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
        EZServiceInfo *serviceInfo = [self getServiceInfo:type];
        if (!serviceInfo) {
            serviceInfo = [EZServiceInfo new];
            serviceInfo.type = type;
            serviceInfo.enabled = YES;
            [self saveServiceInfo:serviceInfo type:type];
        }
    }
}

- (void)setServiceType:(EZServiceType)type enabled:(BOOL)enable {
    EZServiceInfo *serviceInfo = [self getServiceInfo:type];
    serviceInfo.enabled = enable;
    [self saveServiceInfo:serviceInfo type:type];
}

- (void)saveServiceInfo:(EZServiceInfo *)info type:(EZServiceType)type {
    NSData *data = [info mj_JSONData];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self keyForType:type]];
}

- (EZServiceInfo *)getServiceInfo:(EZServiceType)type {
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
