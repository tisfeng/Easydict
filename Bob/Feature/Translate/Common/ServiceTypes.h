//
//  TranslateTypeMap.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateService.h"

NS_ASSUME_NONNULL_BEGIN

@interface ServiceTypes : NSObject

+ (NSArray<EDServiceType> *)allServiceTypes;

+ (NSDictionary<EDServiceType, TranslateService *> *)serviceDict;

+ (TranslateService *)serviceWithType:(EDServiceType)type;

@end

NS_ASSUME_NONNULL_END
