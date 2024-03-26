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

@interface EZServiceTypes : NSObject

@property (nonatomic, copy, readonly) NSArray<EZServiceType> *allServiceTypes;

+ (instancetype)shared;

- (nullable EZQueryService *)serviceWithType:(EZServiceType)type;

- (NSArray<EZQueryService *> *)servicesFromTypes:(NSArray<EZServiceType> *)types;

@end

NS_ASSUME_NONNULL_END
