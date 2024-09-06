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
#import "EZAppModel.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZServiceHasUpdatedNotification = @"EZServiceHasUpdatedNotification";
static NSString *const EZWindowTypeKey = @"EZWindowTypeKey";
static NSString *const EZAutoQueryKey = @"EZAutoQueryKey";

@interface EZLocalStorage : NSObject

#pragma mark - Disabled AppModel

@property (nonatomic, copy) NSArray<EZAppModel *> *selectTextTypeAppModelList;


+ (instancetype)shared;

+ (void)destroySharedInstance;


- (NSArray<NSString *> *)allServiceTypes:(EZWindowType)windowType;
- (void)setAllServiceTypes:(NSArray<NSString *> *)allServiceTypes windowType:(EZWindowType)windowType;

- (NSArray<EZQueryService *> *)allServices:(EZWindowType)windowType;
// pass service type with uuid to support service multi instance 
- (EZQueryService *)service:(NSString *)serviceTypeId windowType:(EZWindowType)windowType;

- (nullable EZServiceInfo *)serviceInfoWithType:(EZServiceType)type serviceId:(NSString *)serviceId windowType:(EZWindowType)windowType;
- (void)setServiceInfo:(EZServiceInfo *)service windowType:(EZWindowType)windowType;

- (void)setService:(EZQueryService *)service windowType:(EZWindowType)windowType;

- (void)setEnabledQuery:(BOOL)enabledQuery serviceType:(EZServiceType)serviceType serviceId:(NSString *)serviceId windowType:(EZWindowType)windowType;

- (void)increaseQueryCount:(NSString *)queryText;
- (NSInteger)queryCount;
- (NSInteger)queryCharacterCount;

- (void)increaseQueryService:(EZQueryService *)service;

- (BOOL)hasFreeQuotaLeft:(EZQueryService *)service;

- (BOOL)isNewUser;

@end

NS_ASSUME_NONNULL_END
