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

static NSString *const kEasydictHelperBundleId = @"com.izual.EasydictHelper";

static NSString *const kAutoSelectTextKey = @"EZConfiguration_kAutoSelectTextKey";
static NSString *const kClickQueryKey = @"EZConfiguration_kClickQueryKey";
static NSString *const kLaunchAtStartupKey = @"EZConfiguration_kLaunchAtStartupKey";
static NSString *const kFromKey = @"EZConfiguration_kFromKey";
static NSString *const kToKey = @"EZConfiguration_kToKey";
static NSString *const kHideMainWindowKey = @"EZConfiguration_kHideMainWindowKey";
static NSString *const kAutoQueryOCTTextKey = @"EZConfiguration_kAutoQueryOCTTextKey";
static NSString *const kAutoQuerySelectedTextKey = @"EZConfiguration_kAutoQuerySelectedTextKey";
static NSString *const kAutoQueryPastedTextKey = @"EZConfiguration_kAutoQueryPastedTextKey";
static NSString *const kAutoPlayAudioKey = @"EZConfiguration_kAutoPlayAudioKey";
static NSString *const kAutoCopySelectedTextKey = @"EZConfiguration_kAutoCopySelectedTextKey";
static NSString *const kAutoCopyOCRTextKey = @"EZConfiguration_kAutoCopyOCRTextKey";
static NSString *const kLanguageDetectOptimizeTypeKey = @"EZConfiguration_kLanguageDetectOptimizeTypeKey";
static NSString *const kShowGoogleLinkKey = @"EZConfiguration_kShowGoogleLinkKey";
static NSString *const kShowEudicLinkKey = @"EZConfiguration_kShowEudicLinkKey";
static NSString *const kHideMenuBarIconKey = @"EZConfiguration_kHideMenuBarIconKey";
static NSString *const kShowFixedWindowPositionKey = @"EZConfiguration_kShowFixedWindowPositionKey";
static NSString *const kWindowFrameKey = @"EZConfiguration_kWindowFrameKey";
static NSString *const kAutomaticallyChecksForUpdatesKey = @"EZConfiguration_kAutomaticallyChecksForUpdatesKey";
static NSString *const kAdjustPopButtomOriginKey = @"EZConfiguration_kAdjustPopButtomOriginKey";
static NSString *const kDisableEmptyCopyBeepKey = @"EZConfiguration_kDisableEmptyCopyBeepKey";
static NSString *const kAllowCrashLogKey = @"EZConfiguration_kAllowCrashLogKey";
static NSString *const kAllowAnalyticsKey = @"EZConfiguration_kAllowAnalyticsKey";
static NSString *const kClearInputKey = @"EZConfiguration_kClearInputKey";


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
    self.from = [NSUserDefaults mm_readString:kFromKey defaultValue:EZLanguageAuto];
    self.to = [NSUserDefaults mm_readString:kToKey defaultValue:EZLanguageAuto];

    self.autoSelectText = [NSUserDefaults mm_readBool:kAutoSelectTextKey defaultValue:YES];
    self.clickQuery = [NSUserDefaults mm_readBool:kClickQueryKey defaultValue:NO];
    self.autoPlayAudio = [NSUserDefaults mm_readBool:kAutoPlayAudioKey defaultValue:NO];
    self.launchAtStartup = [NSUserDefaults mm_readBool:kLaunchAtStartupKey defaultValue:NO];
    self.hideMainWindow = [NSUserDefaults mm_readBool:kHideMainWindowKey defaultValue:YES];
    self.autoQueryOCRText = [NSUserDefaults mm_readBool:kAutoQueryOCTTextKey defaultValue:YES];
    self.autoQuerySelectedText = [NSUserDefaults mm_readBool:kAutoQuerySelectedTextKey defaultValue:YES];
    self.autoQueryPastedText = [NSUserDefaults mm_readBool:kAutoQueryPastedTextKey defaultValue:NO];
    self.autoCopyOCRText = [NSUserDefaults mm_readBool:kAutoCopyOCRTextKey defaultValue:NO];
    self.autoCopySelectedText = [NSUserDefaults mm_readBool:kAutoCopySelectedTextKey defaultValue:NO];
    self.languageDetectOptimize = [NSUserDefaults mm_readInteger:kLanguageDetectOptimizeTypeKey defaultValue:EZLanguageDetectOptimizeNone];
    self.showGoogleQuickLink = [NSUserDefaults mm_readBool:kShowGoogleLinkKey defaultValue:YES];
    self.showEudicQuickLink = [NSUserDefaults mm_readBool:kShowEudicLinkKey defaultValue:YES];
    self.hideMenuBarIcon = [NSUserDefaults mm_readBool:kHideMenuBarIconKey defaultValue:NO];
    self.fixedWindowPosition = [NSUserDefaults mm_readInteger:kShowFixedWindowPositionKey defaultValue:EZShowWindowPositionRight];
    self.automaticallyChecksForUpdates = [NSUserDefaults mm_readBool:kAutomaticallyChecksForUpdatesKey defaultValue:YES];
    self.adjustPopButtomOrigin = [NSUserDefaults mm_readBool:kAdjustPopButtomOriginKey defaultValue:NO];
    self.disableEmptyCopyBeep = [NSUserDefaults mm_readBool:kDisableEmptyCopyBeepKey defaultValue:YES];
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

- (void)setAutoSelectText:(BOOL)autoSelectText {
    _autoSelectText = autoSelectText;

    [NSUserDefaults mm_write:@(autoSelectText) forKey:kAutoSelectTextKey];
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
        [self updateLoginItemWithLaunchAtStartup2:launchAtStartup];
    }
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecksForUpdates {
    [NSUserDefaults mm_write:@(automaticallyChecksForUpdates) forKey:kAutomaticallyChecksForUpdatesKey];

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

- (void)setHideMainWindow:(BOOL)hideMainWindow {
    _hideMainWindow = hideMainWindow;

    [NSUserDefaults mm_write:@(hideMainWindow) forKey:kHideMainWindowKey];
    
    [EZWindowManager.shared showOrHideDockAppAndMainWindow];
    [EZWindowManager.shared updatePopButtonQueryAction];
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

- (void)setDisableEmptyCopyBeep:(BOOL)disableEmptyCopyBeep {
    _disableEmptyCopyBeep = disableEmptyCopyBeep;

    [NSUserDefaults mm_write:@(disableEmptyCopyBeep) forKey:kDisableEmptyCopyBeepKey];
}

- (void)setAllowCrashLog:(BOOL)allowCrashLog {
    _allowCrashLog = allowCrashLog;

    [NSUserDefaults mm_write:@(allowCrashLog) forKey:kAllowCrashLogKey];
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

#pragma mark -

- (void)updateLoginItemWithLaunchAtStartup:(BOOL)launchAtStartup {
    //    [self isLoginItemEnabled];

    NSString *helperBundleId = [self helperBundleId];

    NSError *error;
    if (@available(macOS 13.0, *)) {
        
        /**
         FIX: https://github.com/tisfeng/Easydict/issues/79
         
         Ref: https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/cross_development/Using/using.html#//apple_ref/doc/uid/20002000-1114741-CJADDEIB
         */
        
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1300
    // code only compiled when targeting OS X and not iOS
    // note use of 1050 instead of __MAC_10_5

        // Ref: https://www.bilibili.com/read/cv19361413
        // ???: Why does it not work?
        SMAppService *appService = [SMAppService loginItemServiceWithIdentifier:helperBundleId];
        BOOL success;
        if (launchAtStartup) {
            success = [appService registerAndReturnError:&error];
        } else {
            success = [appService unregisterAndReturnError:&error];
        }
        if (error) {
            MMLogInfo(@"SMAppService error: %@", error);
        }
        if (!success) {
            MMLogInfo(@"SMAppService fail");
        }
#endif
    } else {
        // Ref: https://nyrra33.com/2019/09/03/cocoa-launch-at-startup-best-practice/
        BOOL success = SMLoginItemSetEnabled((__bridge CFStringRef)helperBundleId, launchAtStartup);
        if (!success) {
            MMLogInfo(@"SMLoginItemSetEnabled fail");
        }
    }
}

/// Use apple script to implement launch at start up, or delete.
- (void)updateLoginItemWithLaunchAtStartup2:(BOOL)launchAtStartup {
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

// hide menu bar icon
- (void)hideMenuBarIcon:(BOOL)hidden {
    EZMenuItemManager *statusItem = [EZMenuItemManager shared];
    if (self.hideMenuBarIcon) {
        [statusItem remove];
    } else {
        [statusItem setup];
    }
}

@end
