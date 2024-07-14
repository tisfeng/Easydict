//
//  EZServiceInfo.m
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZServiceInfo.h"

@implementation EZServiceInfo

+ (instancetype)serviceInfoWithService:(EZQueryService *)service {
    EZServiceInfo *serviceInfo = [[EZServiceInfo alloc] init];
    serviceInfo.type = service.serviceType;
    serviceInfo.enabled = service.enabled;
    serviceInfo.enabledQuery = service.enabledQuery;
    serviceInfo.windowType = service.windowType;

    return serviceInfo;
}

@end
