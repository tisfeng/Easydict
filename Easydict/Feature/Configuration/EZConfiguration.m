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
#import <ApplicationServices/ApplicationServices.h>

static NSString *const kAutoSelectTextKey = @"configuration_auto_select_text";
static NSString *const kLaunchAtStartupKey = @"configuration_launch_at_startup";
static NSString *const kFromKey = @"configuration_from";
static NSString *const kToKey = @"configuration_to";

static NSString *const kEasydictHelperBundleId = @"com.izual.easydictHelper";

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
    NSNumber *autoSelectText = [NSUserDefaults mm_read:kAutoSelectTextKey];
    if (autoSelectText == nil) {
        autoSelectText = [NSUserDefaults mm_read:kAutoSelectTextKey defaultValue:@(YES) checkClass:NSNumber.class];
    }
    self.autoSelectText = [autoSelectText boolValue];

    NSNumber *launchAtStartup = [NSUserDefaults mm_read:kLaunchAtStartupKey];
    if (launchAtStartup == nil) {
        launchAtStartup = [NSUserDefaults mm_read:kLaunchAtStartupKey defaultValue:@(YES) checkClass:NSNumber.class];
    }
    self.launchAtStartup = [launchAtStartup boolValue];

    NSString *from = [NSUserDefaults mm_read:kFromKey];
    if (from == nil) {
        from = [NSUserDefaults mm_read:kFromKey defaultValue:EZLanguageAuto checkClass:NSString.class];
    }
    self.from = from;

    NSString *to = [NSUserDefaults mm_read:kToKey];
    if (to == nil) {
        to = [NSUserDefaults mm_read:kToKey defaultValue:EZLanguageAuto checkClass:NSString.class];
    }
    self.to = to;
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

    NSString *helperBundleId = [self helperBundleId];
    SMLoginItemSetEnabled((__bridge CFStringRef)helperBundleId, launchAtStartup);
}

- (BOOL)isLoginItemEnabled {
    BOOL enabled = NO;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFArrayRef loginItems = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
#pragma clang diagnostic pop

    for (id item in (__bridge NSArray *)loginItems) {
        NSString *helperBundleId = [self helperBundleId];

        if ([[[item objectForKey:@"Label"] description] isEqualToString:helperBundleId]) {
            enabled = YES;
            break;
        }
    }
    CFRelease(loginItems);
    return enabled;
}

- (NSString *)helperBundleId {
#if DEBUG
    NSString *helper = [NSString stringWithFormat:@"%@-debug", kEasydictHelperBundleId];
#else
    NSString *helper = kEasydictHelperBundleId;
#endif
    return helper;
}

@end
