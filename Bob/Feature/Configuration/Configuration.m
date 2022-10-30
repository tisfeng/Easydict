//
//  Configuration.m
//  Bob
//
//  Created by ripper on 2019/11/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "Configuration.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Sparkle/Sparkle.h>

#define kAutoCopyTranslateResultKey @"configuration_auto_copy_translate_result"
#define kLaunchAtStartupKey @"configuration_launch_at_startup"

#define kTranslateIdentifierKey @"configuration_translate_identifier"
#define kFromKey @"configuration_from"
#define kToKey @"configuration_to"
#define kPinKey @"configuration_pin"
#define kFoldKey @"configuration_fold"

@implementation Configuration

static Configuration *_instance;
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
    self.autoCopyTranslateResult = [[NSUserDefaults mm_read:kAutoCopyTranslateResultKey defaultValue:@NO checkClass:NSNumber.class] boolValue];
    self.translateIdentifier = [NSUserDefaults mm_read:kTranslateIdentifierKey defaultValue:nil checkClass:NSString.class];
    self.from = [[NSUserDefaults mm_read:kFromKey defaultValue:@(Language_auto) checkClass:NSNumber.class] integerValue];
    self.to = [[NSUserDefaults mm_read:kToKey defaultValue:@(Language_auto) checkClass:NSNumber.class] integerValue];
    self.isPin = [[NSUserDefaults mm_read:kPinKey defaultValue:@NO checkClass:NSNumber.class] boolValue];
    self.isFold = [[NSUserDefaults mm_read:kFoldKey defaultValue:@NO checkClass:NSNumber.class] boolValue];
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

- (void)setAutoCopyTranslateResult:(BOOL)autoCopyTranslateResult {
    _autoCopyTranslateResult = autoCopyTranslateResult;
    [NSUserDefaults mm_write:@(autoCopyTranslateResult) forKey:kAutoCopyTranslateResultKey];
}

- (void)setLaunchAtStartup:(BOOL)launchAtStartup {
    [NSUserDefaults mm_write:@(launchAtStartup) forKey:kLaunchAtStartupKey];
    [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecksForUpdates {
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:automaticallyChecksForUpdates];
}

- (void)setTranslateIdentifier:(NSString *)translateIdentifier {
    _translateIdentifier = translateIdentifier;
    [NSUserDefaults mm_write:translateIdentifier forKey:kTranslateIdentifierKey];
}

- (void)setFrom:(Language)from {
    _from = from;
    [NSUserDefaults mm_write:@(from) forKey:kFromKey];
}

- (void)setTo:(Language)to {
    _to = to;
    [NSUserDefaults mm_write:@(to) forKey:kToKey];
}

- (void)setIsPin:(BOOL)isPin {
    _isPin = isPin;
    [NSUserDefaults mm_write:@(isPin) forKey:kPinKey];
}

- (void)setIsFold:(BOOL)isFold {
    _isFold = isFold;
    [NSUserDefaults mm_write:@(isFold) forKey:kFoldKey];
}

#pragma mark -

- (void)updateLoginItemWithLaunchAtStartup:(BOOL)launchAtStartup {
    // 注册启动项
    // https://nyrra33.com/2019/09/03/cocoa-launch-at-startup-best-practice/
#if DEBUG
    NSString *helper = [NSString stringWithFormat:@"com.ripperhe.BobHelper-debug"];
#else
    NSString *helper = [NSString stringWithFormat:@"com.ripperhe.BobHelper"];
#endif
    SMLoginItemSetEnabled((__bridge CFStringRef)helper, launchAtStartup);
}

@end
