//
//  EZServiceStorage.h
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZServiceInfo.h"
#import "EZLayoutManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZServiceHasUpdatedNotification = @"EZServiceHasUpdatedNotification";
static NSString *const EZWindowTypeKey = @"EZWindowTypeKey";

@interface EZLocalStorage : NSObject

+ (instancetype)shared;

- (NSArray<EZServiceType> *)allServiceTypes:(EZWindowType)windowType;
- (void)setAllServiceTypes:(NSArray<EZServiceType> *)allServiceTypes windowType:(EZWindowType)windowType;

- (NSArray<EZQueryService *> *)allServices:(EZWindowType)windowType;

- (EZServiceInfo *)serviceInfoWithType:(EZServiceType)type windowType:(EZWindowType)windowType;
- (void)setServiceInfo:(EZServiceInfo *)service windowType:(EZWindowType)windowType;

- (void)setService:(EZQueryService *)service windowType:(EZWindowType)windowType;

- (void)setEnabledQuery:(BOOL)enabledQuery serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType;

@end

NS_ASSUME_NONNULL_END
