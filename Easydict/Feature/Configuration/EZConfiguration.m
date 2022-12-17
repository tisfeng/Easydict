//
//  EZConfiguration.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZConfiguration.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Sparkle/Sparkle.h>

static NSString *const kAutoSelectTextKey = @"configuration_auto_select_text";
static NSString *const kLaunchAtStartupKey = @"configuration_launch_at_startup";
static NSString *const kFromKey = @"configuration_from";
static NSString *const kToKey = @"configuration_to";

@implementation EZConfiguration

static EZConfiguration *_instance;
+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
        [_instance setup];
    });
    return _instance;
}

- (void)setup {
    self.autoSelectText = [[NSUserDefaults mm_read:kAutoSelectTextKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.launchAtStartup = [[NSUserDefaults mm_read:kLaunchAtStartupKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.from = [NSUserDefaults mm_read:kFromKey defaultValue:EZLanguageAuto checkClass:NSString.class];
    self.to = [NSUserDefaults mm_read:kToKey defaultValue:EZLanguageAuto checkClass:NSString.class];
}

#pragma mark - getter

- (BOOL)launchAtStartup {
    BOOL launchAtStartup = [[NSUserDefaults mm_read:kLaunchAtStartupKey] boolValue];
    [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
    return launchAtStartup;
}

- (BOOL)automaticallyChecksForUpdates {
    return [SUUpdater sharedUpdater].automaticallyChecksForUpdates;
}

#pragma mark - setter

- (void)setAutoSelectText:(BOOL)autoSelectText {
    _autoSelectText = autoSelectText;
    [NSUserDefaults mm_write:@(autoSelectText) forKey:kAutoSelectTextKey];
}

- (void)setLaunchAtStartup:(BOOL)launchAtStartup {
    [NSUserDefaults mm_write:@(launchAtStartup) forKey:kLaunchAtStartupKey];
    [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecksForUpdates {
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:automaticallyChecksForUpdates];
}

- (void)setFrom:(EZLanguage)from {
    _from = from;
    [NSUserDefaults mm_write:from forKey:kFromKey];
}

- (void)setTo:(EZLanguage)to {
    _to = to;
    [NSUserDefaults mm_write:to forKey:kToKey];
}


#pragma mark -

- (void)updateLoginItemWithLaunchAtStartup:(BOOL)launchAtStartup {
    // 注册启动项
    // https://nyrra33.com/2019/09/03/cocoa-launch-at-startup-best-practice/
#if DEBUG
    NSString *helper = [NSString stringWithFormat:@"com.izual.easydictHelper-debug"];
#else
    NSString *helper = [NSString stringWithFormat:@"com.izual.easydictHelper"];
#endif
    SMLoginItemSetEnabled((__bridge CFStringRef)helper, launchAtStartup);
}

@end
