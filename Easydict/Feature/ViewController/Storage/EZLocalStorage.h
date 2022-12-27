//
//  EZServiceStorage.h
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZServiceInfo.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZServiceHasUpdatedNotification = @"EZServiceHasUpdatedNotification";

@interface EZLocalStorage : NSObject

@property (nonatomic, strong) NSArray<EZServiceType> *allServiceTypes;
@property (nonatomic, strong, readonly) NSArray<EZQueryService *> *allServices;

+ (instancetype)shared;

- (EZServiceInfo *)serviceInfoWithType:(EZServiceType)type;
- (void)saveServiceInfo:(EZServiceInfo *)service;

- (void)saveService:(EZQueryService *)service;

- (void)setServiceType:(EZServiceType)type enabledQuery:(BOOL)enabledQuery;

@end

NS_ASSUME_NONNULL_END
