//
//  EZConfiguration+EZUserData.m
//  Easydict
//
//  Created by tisfeng on 2023/6/21.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZConfiguration+EZUserData.h"

@implementation EZConfiguration (EZUserData)

- (NSDictionary *)userDefaultsData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appUserDefaultsData = [userDefaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    NSMutableDictionary *userConfigDict = [NSMutableDictionary dictionary];
    
    for (NSString *key in appUserDefaultsData) {
        id value = [appUserDefaultsData objectForKey:key];
//        NSLog(@"Key: %@, Value: %@", key, value);
        
        if (![key hasPrefix:@"MASPreferences"] && ![value isKindOfClass:[NSData class]]) {
            userConfigDict[key] = value;
        }
    }
    
    return appUserDefaultsData;
}

- (void)saveUserDefaultsDataToDownloadFolder {
    NSDictionary *userDefaultsData = [self userDefaultsData];
    [self writeDictToDownloadFolder:userDefaultsData];
}

- (void)resetUserDefaultsData {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleIdentifier];
}

/// Convert dict to plist, and save it to download folder
- (void)writeDictToDownloadFolder:(NSDictionary *)dict {
    NSString *downloadPath = [self downloadPath];
    
    NSString *name = [[NSProcessInfo processInfo] processName];
    NSString *date = [self currentDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.plist", name, date];
    NSString *plistPath = [downloadPath stringByAppendingPathComponent:fileName];
    
    // 将 NSDictionary 转换为 NSData
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    
    if (error) {
        NSLog(@"Failed to convert dictionary to plist: %@", error);
        return;
    }
    
    // 写入 plist 文件
    BOOL success = [plistData writeToFile:plistPath atomically:YES];
    
    if (success) {
        NSLog(@"Plist saved to download folder: %@", plistPath);
    } else {
        NSLog(@"Failed to save plist to download folder");
    }
}

- (NSString  *)downloadPath {
    NSArray *downloadPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    NSString *downloadPath = [downloadPaths firstObject];
    return downloadPath;
}

- (NSString *)currentDate {
    NSDate *currentDate = [NSDate date];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;

    NSString *formattedDate = [formatter stringFromDate:currentDate];
    NSLog(@"Formatted Date: %@", formattedDate);
    
    return formattedDate;
}

@end
