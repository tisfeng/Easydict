//
//  EZLog.m
//  Easydict
//
//  Created by tisfeng on 2022/12/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLog.h"

@import FirebaseAnalytics;
@import AppCenterAnalytics;

@implementation EZLog

+ (void)logWindowAppear:(EZWindowType)windowType {
    NSString *windowName = [EZLayoutManager.shared windowName:windowType];
    NSString *name = [NSString stringWithFormat:@"show_%@", windowName];
    [self logEventWithName:name parameters:nil];
}

+ (void)logService:(EZQueryService *)service {
    NSString *name = @"query_service";
    EZQueryModel *model = service.queryModel;
    NSDictionary *dict = @{
        @"serviceType" : service.serviceType,
        @"queryType" : model.queryType,
        @"from" : model.queryFromLanguage,
        @"to" : model.queryTargetLanguage,
    };
    [self logEventWithName:name parameters:dict];
}

/// Log event. ⚠️ Event name must contain only letters, numbers, or underscores.
+ (void)logEventWithName:(NSString *)name parameters:(nullable NSDictionary *)dict {
//    NSLog(@"log event: %@, %@", name, dict);
    [MSACAnalytics trackEvent:name withProperties:dict];
    [FIRAnalytics logEventWithName:name parameters:dict];
}

@end
