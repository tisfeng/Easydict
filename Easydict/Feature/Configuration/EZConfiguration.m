//
//  EZConfiguration.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZConfiguration.h"
#import <ServiceManagement/ServiceManagement.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Sparkle/Sparkle.h>
#import "EZMenuItemManager.h"
#import "EZWindowManager.h"
#import "EZExeCommand.h"
#import "EZLog.h"

static NSString *const kEasydictHelperBundleId = @"com.izual.EasydictHelper";

static NSString *const kFirstLanguageKey = @"EZConfiguration_kFirstLanguageKey";
static NSString *const kSecondLanguageKey = @"EZConfiguration_kSecondLanguageKey";

static NSString *const kFromKey = @"EZConfiguration_kFromKey";
static NSString *const kToKey = @"EZConfiguration_kToKey";

static NSString *const kAutoSelectTextKey = @"EZConfiguration_kAutoSelectTextKey";
static NSString *const kForceAutoGetSelectedText = @"EZConfiguration_kForceAutoGetSelectedText";
static NSString *const kDisableEmptyCopyBeepKey = @"EZConfiguration_kDisableEmptyCopyBeepKey";
static NSString *const kClickQueryKey = @"EZConfiguration_kClickQueryKey";
static NSString *const kLaunchAtStartupKey = @"EZConfiguration_kLaunchAtStartupKey";
static NSString *const kHideMainWindowKey = @"EZConfiguration_kHideMainWindowKey";
static NSString *const kAutoQueryOCTTextKey = @"EZConfiguration_kAutoQueryOCTTextKey";
static NSString *const kAutoQuerySelectedTextKey = @"EZConfiguration_kAutoQuerySelectedTextKey";
static NSString *const kAutoQueryPastedTextKey = @"EZConfiguration_kAutoQueryPastedTextKey";
static NSString *const kAutoPlayAudioKey = @"EZConfiguration_kAutoPlayAudioKey";
static NSString *const kAutoCopySelectedTextKey = @"EZConfiguration_kAutoCopySelectedTextKey";
static NSString *const kAutoCopyOCRTextKey = @"EZConfiguration_kAutoCopyOCRTextKey";
static NSString *const kAutoCopyFirstTranslatedTextKey = @"EZConfiguration_kAutoCopyFirstTranslatedTextKey";
static NSString *const kLanguageDetectOptimizeTypeKey = @"EZConfiguration_kLanguageDetectOptimizeTypeKey";
static NSString *const kShowGoogleLinkKey = @"EZConfiguration_kShowGoogleLinkKey";
static NSString *const kShowEudicLinkKey = @"EZConfiguration_kShowEudicLinkKey";
static NSString *const kHideMenuBarIconKey = @"EZConfiguration_kHideMenuBarIconKey";
static NSString *const kShowFixedWindowPositionKey = @"EZConfiguration_kShowFixedWindowPositionKey";
static NSString *const kWindowFrameKey = @"EZConfiguration_kWindowFrameKey";
static NSString *const kAutomaticallyChecksForUpdatesKey = @"EZConfiguration_kAutomaticallyChecksForUpdatesKey";
static NSString *const kAdjustPopButtomOriginKey = @"EZConfiguration_kAdjustPopButtomOriginKey";
static NSString *const kAllowCrashLogKey = @"EZConfiguration_kAllowCrashLogKey";
static NSString *const kAllowAnalyticsKey = @"EZConfiguration_kAllowAnalyticsKey";
static NSString *const kClearInputKey = @"EZConfiguration_kClearInputKey";


@implementation EZConfiguration

static EZConfiguration *_instance;

+ (instancetype)shared {
    @synchronized (self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
            [_instance setup];
        }
    }
    return _instance;
}

+ (void)destroySharedInstance {
    _instance = nil;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

- (void)setup {
    self.firstLanguage = [NSUserDefaults mm_read:kFirstLanguageKey];
    self.secondLanguage = [NSUserDefaults mm_read:kSecondLanguageKey];
    
    self.from = [NSUserDefaults mm_readString:kFromKey defaultValue:EZLanguageAuto];
    self.to = [NSUserDefaults mm_readString:kToKey defaultValue:EZLanguageAuto];

    self.autoSelectText = [NSUserDefaults mm_readBool:kAutoSelectTextKey defaultValue:YES];
    self.forceAutoGetSelectedText = [NSUserDefaults mm_readBool:kForceAutoGetSelectedText defaultValue:NO];
    self.disableEmptyCopyBeep = [NSUserDefaults mm_readBool:kDisableEmptyCopyBeepKey defaultValue:YES];
    self.clickQuery = [NSUserDefaults mm_readBool:kClickQueryKey defaultValue:NO];
    self.autoPlayAudio = [NSUserDefaults mm_readBool:kAutoPlayAudioKey defaultValue:YES];
    self.launchAtStartup = [NSUserDefaults mm_readBool:kLaunchAtStartupKey defaultValue:NO];
    self.hideMainWindow = [NSUserDefaults mm_readBool:kHideMainWindowKey defaultValue:YES];
    self.autoQueryOCRText = [NSUserDefaults mm_readBool:kAutoQueryOCTTextKey defaultValue:YES];
    self.autoQuerySelectedText = [NSUserDefaults mm_readBool:kAutoQuerySelectedTextKey defaultValue:YES];
    self.autoQueryPastedText = [NSUserDefaults mm_readBool:kAutoQueryPastedTextKey defaultValue:NO];
    self.autoCopyOCRText = [NSUserDefaults mm_readBool:kAutoCopyOCRTextKey defaultValue:NO];
    self.autoCopySelectedText = [NSUserDefaults mm_readBool:kAutoCopySelectedTextKey defaultValue:NO];
    self.autoCopyFirstTranslatedText = [NSUserDefaults mm_readBool:kAutoCopyFirstTranslatedTextKey defaultValue:NO];
    self.languageDetectOptimize = [NSUserDefaults mm_readInteger:kLanguageDetectOptimizeTypeKey defaultValue:EZLanguageDetectOptimizeNone];
    self.showGoogleQuickLink = [NSUserDefaults mm_readBool:kShowGoogleLinkKey defaultValue:YES];
    self.showEudicQuickLink = [NSUserDefaults mm_readBool:kShowEudicLinkKey defaultValue:YES];
    self.hideMenuBarIcon = [NSUserDefaults mm_readBool:kHideMenuBarIconKey defaultValue:NO];
    self.fixedWindowPosition = [NSUserDefaults mm_readInteger:kShowFixedWindowPositionKey defaultValue:EZShowWindowPositionRight];
    self.automaticallyChecksForUpdates = [NSUserDefaults mm_readBool:kAutomaticallyChecksForUpdatesKey defaultValue:YES];
    self.adjustPopButtomOrigin = [NSUserDefaults mm_readBool:kAdjustPopButtomOriginKey defaultValue:NO];
    self.allowCrashLog = [NSUserDefaults mm_readBool:kAllowCrashLogKey defaultValue:YES];
    self.allowAnalytics = [NSUserDefaults mm_readBool:kAllowAnalyticsKey defaultValue:YES];
    self.clearInput = [NSUserDefaults mm_readBool:kClearInputKey defaultValue:NO];
}

#pragma mark - getter

- (BOOL)launchAtStartup {
    BOOL launchAtStartup = [[NSUserDefaults mm_read:kLaunchAtStartupKey] boolValue];
    return launchAtStartup;
}

- (BOOL)automaticallyChecksForUpdates {
    return [SUUpdater sharedUpdater].automaticallyChecksForUpdates;
}

#pragma mark - setter

- (void)setFirstLanguage:(EZLanguage)firstLanguage {
    _firstLanguage = firstLanguage;

    [NSUserDefaults mm_write:firstLanguage forKey:kFirstLanguageKey];
}

- (void)setSecondLanguage:(EZLanguage)secondLanguage {
    _secondLanguage = secondLanguage;

    [NSUserDefaults mm_write:secondLanguage forKey:kSecondLanguageKey];
}

- (void)setFrom:(EZLanguage)from {
    _from = from;

    [NSUserDefaults mm_write:from forKey:kFromKey];
}

- (void)setTo:(EZLanguage)to {
    _to = to;

    [NSUserDefaults mm_write:to forKey:kToKey];
}

- (void)setAutoSelectText:(BOOL)autoSelectText {
    _autoSelectText = autoSelectText;

    [NSUserDefaults mm_write:@(autoSelectText) forKey:kAutoSelectTextKey];
}

- (void)setForceAutoGetSelectedText:(BOOL)forceGetSelectedText {
    _forceAutoGetSelectedText = forceGetSelectedText;

    [NSUserDefaults mm_write:@(forceGetSelectedText) forKey:kForceAutoGetSelectedText];
}

- (void)setDisableEmptyCopyBeep:(BOOL)disableEmptyCopyBeep {
    _disableEmptyCopyBeep = disableEmptyCopyBeep;

    [NSUserDefaults mm_write:@(disableEmptyCopyBeep) forKey:kDisableEmptyCopyBeepKey];
}

- (void)setClickQuery:(BOOL)clickQuery {
    _clickQuery = clickQuery;

    [NSUserDefaults mm_write:@(clickQuery) forKey:kClickQueryKey];
    
    [EZWindowManager.shared updatePopButtonQueryAction];
}

- (void)setLaunchAtStartup:(BOOL)launchAtStartup {
    BOOL oldLaunchAtStartup = self.launchAtStartup;
    
    [NSUserDefaults mm_write:@(launchAtStartup) forKey:kLaunchAtStartupKey];
    
    // Avoid redundant calls, run AppleScript will ask for permission, trigger notification.
    if (launchAtStartup != oldLaunchAtStartup) {
        [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
    }
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecksForUpdates {
    [NSUserDefaults mm_write:@(automaticallyChecksForUpdates) forKey:kAutomaticallyChecksForUpdatesKey];

    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:automaticallyChecksForUpdates];
}

- (void)setHideMainWindow:(BOOL)hideMainWindow {
    _hideMainWindow = hideMainWindow;

    [NSUserDefaults mm_write:@(hideMainWindow) forKey:kHideMainWindowKey];
    
    EZWindowManager *windowManager = EZWindowManager.shared;
    [windowManager updatePopButtonQueryAction];
    if (hideMainWindow) {
        [windowManager closeMainWindowIfNeeded];
    }
}

- (void)setAutoQueryOCRText:(BOOL)autoSnipTranslate {
    _autoQueryOCRText = autoSnipTranslate;

    [NSUserDefaults mm_write:@(autoSnipTranslate) forKey:kAutoQueryOCTTextKey];
}

- (void)setAutoQuerySelectedText:(BOOL)autoQuerySelectedText {
    _autoQuerySelectedText = autoQuerySelectedText;

    [NSUserDefaults mm_write:@(autoQuerySelectedText) forKey:kAutoQuerySelectedTextKey];
}

- (void)setAutoQueryPastedText:(BOOL)autoQueryPastedText {
    _autoQueryPastedText = autoQueryPastedText;

    [NSUserDefaults mm_write:@(autoQueryPastedText) forKey:kAutoQueryPastedTextKey];
}

- (void)setAutoCopyFirstTranslatedText:(BOOL)autoCopyFirstTranslatedText {
    _autoCopyFirstTranslatedText = autoCopyFirstTranslatedText;

    [NSUserDefaults mm_write:@(autoCopyFirstTranslatedText) forKey:kAutoCopyFirstTranslatedTextKey];
}

- (void)setAutoPlayAudio:(BOOL)autoPlayAudio {
    _autoPlayAudio = autoPlayAudio;

    [NSUserDefaults mm_write:@(autoPlayAudio) forKey:kAutoPlayAudioKey];
}

- (void)setAutoCopySelectedText:(BOOL)autoCopySelectedText {
    _autoCopySelectedText = autoCopySelectedText;

    [NSUserDefaults mm_write:@(autoCopySelectedText) forKey:kAutoCopySelectedTextKey];
}

- (void)setAutoCopyOCRText:(BOOL)autoCopyOCRText {
    _autoCopyOCRText = autoCopyOCRText;

    [NSUserDefaults mm_write:@(autoCopyOCRText) forKey:kAutoCopyOCRTextKey];
}

- (void)setLanguageDetectOptimize:(EZLanguageDetectOptimize)languageDetectOptimizeType {
    _languageDetectOptimize = languageDetectOptimizeType;

    [NSUserDefaults mm_write:@(languageDetectOptimizeType) forKey:kLanguageDetectOptimizeTypeKey];
}

- (void)setShowGoogleQuickLink:(BOOL)showGoogleLink {
    _showGoogleQuickLink = showGoogleLink;

    [NSUserDefaults mm_write:@(showGoogleLink) forKey:kShowGoogleLinkKey];
    [self postUpdateQuickLinkButtonNotification];
    
    EZMenuItemManager.shared.googleItem.hidden = !showGoogleLink;
}

- (void)setShowEudicQuickLink:(BOOL)showEudicLink {
    _showEudicQuickLink = showEudicLink;

    [NSUserDefaults mm_write:@(showEudicLink) forKey:kShowEudicLinkKey];
    [self postUpdateQuickLinkButtonNotification];
    
    EZMenuItemManager.shared.eudicItem.hidden = !showEudicLink;
}

- (void)setHideMenuBarIcon:(BOOL)hideMenuBarIcon {
    _hideMenuBarIcon = hideMenuBarIcon;

    [NSUserDefaults mm_write:@(hideMenuBarIcon) forKey:kHideMenuBarIconKey];

    [self hideMenuBarIcon:hideMenuBarIcon];
}

- (void)setFixedWindowPosition:(EZShowWindowPosition)showFixedWindowPosition {
    _fixedWindowPosition = showFixedWindowPosition;

    [NSUserDefaults mm_write:@(showFixedWindowPosition) forKey:kShowFixedWindowPositionKey];
}

- (void)setAdjustPopButtomOrigin:(BOOL)adjustPopButtomOrigin {
    _adjustPopButtomOrigin = adjustPopButtomOrigin;

    [NSUserDefaults mm_write:@(adjustPopButtomOrigin) forKey:kAdjustPopButtomOriginKey];
}

- (void)setAllowCrashLog:(BOOL)allowCrashLog {
    _allowCrashLog = allowCrashLog;

    [NSUserDefaults mm_write:@(allowCrashLog) forKey:kAllowCrashLogKey];
    [EZLog setCrashEnabled:allowCrashLog];
}

- (void)setAllowAnalytics:(BOOL)allowAnalytics {
    _allowAnalytics = allowAnalytics;

    [NSUserDefaults mm_write:@(allowAnalytics) forKey:kAllowAnalyticsKey];
}

- (void)setClearInput:(BOOL)clearInput {
    _clearInput = clearInput;

    [NSUserDefaults mm_write:@(clearInput) forKey:kClearInputKey];
}


#pragma mark - Window Frame

- (CGRect)windowFrameWithType:(EZWindowType)windowType {
    NSString *key = [self windowFrameKey:windowType];
    NSString *frameString = [NSUserDefaults mm_read:key];
    CGRect frame = NSRectFromString(frameString);
    return frame;
}
- (void)setWindowFrame:(CGRect)frame windowType:(EZWindowType)windowType {
    NSString *key = [self windowFrameKey:windowType];
    NSString *frameString = NSStringFromRect(frame);
    [NSUserDefaults mm_write:frameString forKey:key];
}

- (NSString *)windowFrameKey:(EZWindowType)windowType {
    NSString *key = [NSString stringWithFormat:@"%@_%@", kWindowFrameKey, @(windowType)];
    return key;
}

#pragma mark - Lanuch at login

/// Use apple script to implement launch at start up, or delete.
- (void)updateLoginItemWithLaunchAtStartup:(BOOL)launchAtStartup {
    // ???: name is CFBundleExecutable, or CFBundleName ?
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
    NSString *appBundlePath = [[NSBundle mainBundle] bundlePath];
        
    NSString *script = [NSString stringWithFormat:@"\
        tell application \"System Events\" to get the name of every login item\n\
        tell application \"System Events\"\n\
            set loginItems to every login item\n\
            repeat with aLoginItem in loginItems\n\
                if (aLoginItem's name is \"%@\") then\n\
                    delete aLoginItem\n\
                end if\n\
            end repeat\n\
            if %@ then\n\
                make login item at end with properties {path:\"%@\", hidden:false}\n\
            end if\n\
        end tell"
                        , appName,
                        launchAtStartup ? @"true" : @"false",
                        appBundlePath
    ];

    EZExeCommand *exeCommand = [[EZExeCommand alloc] init];
    [exeCommand runAppleScriptWithTask:script completionHandler:^(NSString * _Nonnull result, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"launchAtStartup error: %@", error);
        } else {
            NSLog(@"launchAtStartup result: %@", result);
        }
    }];
}

//- (void)updateLoginItemWithLaunchAtStartup2:(BOOL)launchAtStartup {
//    //    [self isLoginItemEnabled];
//
//    NSString *helperBundleId = [self helperBundleId];
//
//    NSError *error;
//    if (@available(macOS 13.0, *)) {
//
//        /**
//         FIX: https://github.com/tisfeng/Easydict/issues/79
//
//         Ref: https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/cross_development/Using/using.html#//apple_ref/doc/uid/20002000-1114741-CJADDEIB
//         */
//
//#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1300
//    // code only compiled when targeting OS X and not iOS
//    // note use of 1050 instead of __MAC_10_5
//
//        // Ref: https://www.bilibili.com/read/cv19361413
//        // ???: Why does it not work?
//        SMAppService *appService = [SMAppService loginItemServiceWithIdentifier:helperBundleId];
//        BOOL success;
//        if (launchAtStartup) {
//            success = [appService registerAndReturnError:&error];
//        } else {
//            success = [appService unregisterAndReturnError:&error];
//        }
//        if (error) {
//            MMLogInfo(@"SMAppService error: %@", error);
//        }
//        if (!success) {
//            MMLogInfo(@"SMAppService fail");
//        }
//#endif
//    } else {
//        // Ref: https://nyrra33.com/2019/09/03/cocoa-launch-at-startup-best-practice/
//        BOOL success = SMLoginItemSetEnabled((__bridge CFStringRef)helperBundleId, launchAtStartup);
//        if (!success) {
//            MMLogInfo(@"SMLoginItemSetEnabled fail");
//        }
//    }
//}


- (BOOL)isLoginItemEnabled {
    BOOL enabled = NO;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFArrayRef loginItems = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
#pragma clang diagnostic pop

    NSString *helperBundleId = [self helperBundleId];
    for (id item in (__bridge NSArray *)loginItems) {
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
    NSString *helperId = [NSString stringWithFormat:@"%@-debug", kEasydictHelperBundleId];
#else
    NSString *helperId = kEasydictHelperBundleId;
#endif
    return helperId;
}

- (void)postUpdateQuickLinkButtonNotification {
    NSNotification *notification = [NSNotification notificationWithName:EZQuickLinkButtonUpdateNotification object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark -

// hide menu bar icon
- (void)hideMenuBarIcon:(BOOL)hidden {
    EZMenuItemManager *statusItem = [EZMenuItemManager shared];
    if (self.hideMenuBarIcon) {
        [statusItem remove];
    } else {
        [statusItem setup];
    }
}


#pragma mark - Intelligent Query Mode

- (void)setIntelligentQueryMode:(BOOL)enabled windowType:(EZWindowType)windowType {
    NSString *key = [EZConstKey constkey:EZIntelligentQueryModeKey windowType:windowType];
    NSString *stringValue = [NSString stringWithFormat:@"%d", enabled];
    [NSUserDefaults mm_write:stringValue forKey:key];
}
- (BOOL)intelligentQueryModeForWindowType:(EZWindowType)windowType {
    NSString *key = [EZConstKey constkey:EZIntelligentQueryModeKey windowType:windowType];
    NSString *stringValue = [NSUserDefaults mm_readString:key defaultValue:@"0"];
    return [stringValue boolValue];
}

#pragma mark - Query Text Type of Service

- (void)setQueryTextType:(EZQueryTextType)queryTextType serviceType:(EZServiceType)serviceType {
    // easydict://writeKeyValue?IntelligentQueryMode-window1=1
    NSString *key = [EZConstKey constkey:EZQueryTextTypeKey serviceType:serviceType];
    [NSUserDefaults mm_write:@(queryTextType) forKey:key];
}
- (EZQueryTextType)queryTextTypeForServiceType:(EZServiceType)serviceType {
    NSString *key = [EZConstKey constkey:EZQueryTextTypeKey serviceType:serviceType];
    EZQueryTextType type = [NSUserDefaults mm_readInteger:key defaultValue:0];
    return type;
}

#pragma mark - Intelligent Query Text Type of Service

- (void)setIntelligentQueryTextType:(EZQueryTextType)queryTextType serviceType:(EZServiceType)serviceType {
    NSString *key = [EZConstKey constkey:EZIntelligentQueryTextTypeKey serviceType:serviceType];
    /**
     easydict://writeKeyValue?Google-IntelligentQueryTextType=5
     URL key value is string type, so we need to save vlue as string type.
     */
    NSString *stringValue = [NSString stringWithFormat:@"%ld", queryTextType];
    [NSUserDefaults mm_write:stringValue forKey:key];
}
- (EZQueryTextType)intelligentQueryTextTypeForServiceType:(EZServiceType)serviceType {
    NSString *key = [EZConstKey constkey:EZIntelligentQueryTextTypeKey serviceType:serviceType];
    NSString *stringValue = [NSUserDefaults mm_readString:key defaultValue:@"111"];
    // Convert string to int
    EZQueryTextType type = [stringValue integerValue];
    return type;
}

#pragma mark - Beta
- (void)setBeta:(BOOL)beta {
    NSString *stringValue = beta ? @"1" : @"0";
    [NSUserDefaults mm_write:stringValue forKey:EZBetaFeatureKey];
}
- (BOOL)isBeta {
    NSString *stringValue = [NSUserDefaults mm_readString:EZBetaFeatureKey defaultValue:@"0"];
    BOOL isBeta = [stringValue boolValue];
    return isBeta;
}

#pragma mark - Default TTS
- (void)setDefaultTTSServiceType:(EZServiceType _Nonnull)defaultTTSServiceType {
    [NSUserDefaults mm_write:defaultTTSServiceType forKey:EZDefaultTTSServiceKey];
}
- (EZServiceType)defaultTTSServiceType {
    return [NSUserDefaults mm_readString:EZDefaultTTSServiceKey defaultValue:EZServiceTypeApple];
}


#pragma mark -

- (void)enableBetaFeaturesIfNeeded {
    if ([self isBeta]) {
        [self setIntelligentQueryMode:YES windowType:EZWindowTypeMini];
        [self setDefaultTTSServiceType:EZServiceTypeYoudao];
    }
}

@end
