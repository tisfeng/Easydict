//
//  EZLog.m
//  Easydict
//
//  Created by tisfeng on 2022/12/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLog.h"
#import "EZConfiguration.h"

@import FirebaseAnalytics;
@import AppCenterAnalytics;

@implementation EZLog

+ (void)setupCrashLogService {
    if (!EZConfiguration.shared.allowCrashLog) {
        return;
    }

#if !DEBUG
    NSString *key = NSBundle.mainBundle.bundleIdentifier;
    NSString *encryptedAppSecretKey = @"OflP6xig/YV1XCtlLSk/cNXBJiLhBnXiLwaSAkdkUuUlVmWrXlmgCMiuvNzjPCFB";
    NSString *appSecretKey = [FWEncryptorAES decryptText:encryptedAppSecretKey key:key];
    
    // App Center
    [MSACAppCenter start:appSecretKey withServices:@[
        [MSACAnalytics class],
        [MSACCrashes class]
    ]];
    
    // Firebase
    [FIRApp configure];
#endif
}


+ (void)logWindowAppear:(EZWindowType)windowType {
    NSString *windowName = [EZLayoutManager.shared windowName:windowType];
    NSString *name = [NSString stringWithFormat:@"show_%@", windowName];
    [self logEventWithName:name parameters:nil];
}

+ (void)logQueryService:(EZQueryService *)service {
    NSString *name = @"query_service";
    EZQueryModel *model = service.queryModel;
    NSString *textLengthRange = [self textLengthRange:model.queryText];
    NSDictionary *dict = @{
        @"serviceType" : service.serviceType,
        @"actionType" : model.actionType,
        @"from" : model.queryFromLanguage,
        @"to" : model.queryTargetLanguage,
        @"textLength" : textLengthRange,
    };
    [self logEventWithName:name parameters:dict];
}

// Query with queryModel
+ (void)logQuery:(EZQueryModel *)model {
    NSString *name = @"query";
    NSString *textLengthRange = [self textLengthRange:model.queryText];
    NSDictionary *dict = @{
        @"queryType" : model.actionType,
        @"fromLanguage" : model.queryFromLanguage,
        @"toLanguage" : model.queryTargetLanguage,
        @"textLength" : textLengthRange,
    };
    [self logEventWithName:name parameters:dict];
}

/// Get text length range, 1-10, 10-50, 50-200, 200-1000, 1000-5000
+ (NSString *)textLengthRange:(NSString *)text {
    NSInteger length = text.length;
    if (length <= 10) {
        return @"1-10";
    } else if (length <= 50) {
        return @"10-50";
    } else if (length <= 200) {
        return @"50-200";
    } else if (length <= 1000) {
        return @"200-1000";
    } else if (length <= 5000) {
        return @"1000-5000";
    } else {
        return @"5000-∞";
    }
}

/// Log event.
/// ⚠️ Event name must contain only letters, numbers, or underscores.
/// ⚠️ parameters dict key and value both should be NSString.
+ (void)logEventWithName:(NSString *)name parameters:(nullable NSDictionary *)dict {
    //    NSLog(@"log event: %@, %@", name, dict);
    
    if (!EZConfiguration.shared.allowAnalytics) {
        return;
    }
    
#if !DEBUG
        [MSACAnalytics trackEvent:name withProperties:dict];
        [FIRAnalytics logEventWithName:name parameters:dict];
#endif
}

@end
