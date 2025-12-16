//
//  EZServiceInfo.h
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryService.h"
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZServiceInfo : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, assign) EZServiceType type;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL enabledQuery;
@property (nonatomic, assign) EZWindowType windowType;

+ (instancetype)serviceInfoWithService:(EZQueryService *)service;

@end

NS_ASSUME_NONNULL_END
