//
//  TranslateTypeMap.h
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryService.h"
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ServiceTypes)
@interface EZServiceTypes : NSObject

@property (nonatomic, copy, readonly) NSArray<EZServiceType> *allServiceTypes;
@property (nonatomic, copy, readonly) NSArray<NSString *> *allServiceTypeIDs;

+ (instancetype)shared;

- (nullable EZQueryService *)serviceWithType:(NSString *)typeIdIfHave;

- (NSArray<EZQueryService *> *)servicesFromTypes:(NSArray<NSString *> *)types;

@end

NS_ASSUME_NONNULL_END
