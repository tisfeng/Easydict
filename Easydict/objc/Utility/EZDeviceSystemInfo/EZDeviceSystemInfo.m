//
//  EZDeviceSystemInfo.m
//  Easydict
//
//  Created by tisfeng on 2023/7/12.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZDeviceSystemInfo.h"
#import <sys/utsname.h>
#import <sys/sysctl.h>

@implementation EZDeviceSystemInfo

+ (NSDictionary *)getDeviceSystemInfo {
    
    NSDictionary *infoDictionary = NSBundle.mainBundle.infoDictionary;
    // 1.3.4
    NSString *appVersion = infoDictionary[@"CFBundleShortVersionString"];
    NSString *buildVersion = infoDictionary[@"CFBundleVersion"];
    
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    // 版本13.5（版号22G5059d）
    NSString *systemVersion = [processInfo operatingSystemVersionString];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    // arm64
    NSString *machine = [NSString stringWithUTF8String:systemInfo.machine];
    
    NSString *deviceModel = [self getDeviceModel];
    NSString *uuidString = [self getDeviceUUID];
    
    NSDictionary *infoDict = @{
        @"Version" : appVersion,
        @"Build" : buildVersion,
        @"System" : systemVersion,
        @"Device" : deviceModel,
        @"Machine" : machine,
        @"UUID" : uuidString
    };
    
    return infoDict;
}


/// Get device model, MacBookPro18,1
+ (NSString *)getDeviceModel {
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.model", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:model];
    free(model);
    return deviceModel;
}

/// Get device UUID, 4F07896A-1580-5270-A0E8-D7FA9DFA6868
+ (NSString *)getDeviceUUID {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef uuidString = (CFStringRef)IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    NSString *uuid = (__bridge NSString *)(uuidString);
    IOObjectRelease(platformExpert);
    CFRelease(uuidString);
    return uuid;
}

/// Get system version, eg 14.0.0
+ (NSString *)getSystemVersion {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *versionString = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
    return versionString;
}

@end
