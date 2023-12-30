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
#import "EZScriptExecutor.h"
#import "EZLog.h"
#import "EZLanguageManager.h"
#import "AppDelegate.h"
#import "Easydict-Swift.h"
#import "DarkModeManager.h"

static NSString *const kEasydictHelperBundleId = @"com.izual.EasydictHelper";

static NSString *const kFirstLanguageKey = @"EZConfiguration_kFirstLanguageKey";
static NSString *const kSecondLanguageKey = @"EZConfiguration_kSecondLanguageKey";


static NSString *const kFromKey = @"EZConfiguration_kFromKey";
static NSString *const kToKey = @"EZConfiguration_kToKey";

static NSString *const kAutoSelectTextKey = @"EZConfiguration_kAutoSelectTextKey";
static NSString *const kForceAutoGetSelectedText = @"EZConfiguration_kForceAutoGetSelectedText";
static NSString *const kDisableEmptyCopyBeepKey = @"EZConfiguration_kDisableEmptyCopyBeepKey";
static NSString *const kClickQueryKey = @"EZConfiguration_kClickQueryKey";
static NSString *const kAutoQueryOCTTextKey = @"EZConfiguration_kAutoQueryOCTTextKey";
static NSString *const kAutoQuerySelectedTextKey = @"EZConfiguration_kAutoQuerySelectedTextKey";
static NSString *const kAutoQueryPastedTextKey = @"EZConfiguration_kAutoQueryPastedTextKey";
static NSString *const kAutoPlayAudioKey = @"EZConfiguration_kAutoPlayAudioKey";
static NSString *const kAutoCopySelectedTextKey = @"EZConfiguration_kAutoCopySelectedTextKey";
static NSString *const kAutoCopyOCRTextKey = @"EZConfiguration_kAutoCopyOCRTextKey";
static NSString *const kAutoCopyFirstTranslatedTextKey = @"EZConfiguration_kAutoCopyFirstTranslatedTextKey";
static NSString *const kLanguageDetectOptimizeTypeKey = @"EZConfiguration_kLanguageDetectOptimizeTypeKey";
static NSString *const kDefaultTTSServiceTypeKey = @"EZConfiguration_kDefaultTTSServiceTypeKey";
static NSString *const kShowGoogleLinkKey = @"EZConfiguration_kShowGoogleLinkKey";
static NSString *const kShowEudicLinkKey = @"EZConfiguration_kShowEudicLinkKey";
static NSString *const kShowAppleDictionaryLinkKey = @"EZConfiguration_kShowAppleDictionaryLinkKey";
static NSString *const kShowFixedWindowPositionKey = @"EZConfiguration_kShowFixedWindowPositionKey";
static NSString *const kShortcutSelectTranslateWindowTypeKey = @"EZConfiguration_kShortcutSelectTranslateWindowTypeKey";
static NSString *const kMouseSelectTranslateWindowTypeKey = @"EZConfiguration_kMouseSelectTranslateWindowTypeKey";
static NSString *const kWindowFrameKey = @"EZConfiguration_kWindowFrameKey";
static NSString *const kAdjustPopButtomOriginKey = @"EZConfiguration_kAdjustPopButtomOriginKey";
static NSString *const kAllowCrashLogKey = @"EZConfiguration_kAllowCrashLogKey";
static NSString *const kAllowAnalyticsKey = @"EZConfiguration_kAllowAnalyticsKey";
static NSString *const kClearInputKey = @"EZConfiguration_kClearInputKey";
static NSString *const kTranslationControllerFontKey = @"EZConfiguration_kTranslationControllerFontKey";
static NSString *const kApperanceKey = @"EZConfiguration_kApperanceKey";

NSString *const kHideMainWindowKey = @"EZConfiguration_kHideMainWindowKey";
NSString *const kLaunchAtStartupKey = @"EZConfiguration_kLaunchAtStartupKey";
NSString *const kHideMenuBarIconKey = @"EZConfiguration_kHideMenuBarIconKey";
NSString *const kEnableBetaNewAppKey = @"EZConfiguration_kEnableBetaNewAppKey";

@interface EZConfiguration ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) SPUUpdater *updater;

@end

@implementation EZConfiguration

static EZConfiguration *_instance;

+ (instancetype)shared {
    @synchronized(self) {
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
    self.appDelegate = (AppDelegate *)[NSApp delegate];
    
    EZLanguage defaultFirstLanguage = [EZLanguageManager.shared systemPreferredTwoLanguages][0];
    self.firstLanguage = [NSUserDefaults mm_readString:kFirstLanguageKey defaultValue:defaultFirstLanguage];
    EZLanguage defaultSecondLanguage = [EZLanguageManager.shared systemPreferredTwoLanguages][1];
    self.secondLanguage = [NSUserDefaults mm_readString:kSecondLanguageKey defaultValue:defaultSecondLanguage];
    
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
    self.defaultTTSServiceType = [NSUserDefaults mm_readString:kDefaultTTSServiceTypeKey defaultValue:EZServiceTypeYoudao];
    self.showGoogleQuickLink = [NSUserDefaults mm_readBool:kShowGoogleLinkKey defaultValue:YES];
    self.showEudicQuickLink = [NSUserDefaults mm_readBool:kShowEudicLinkKey defaultValue:YES];
    self.showAppleDictionaryQuickLink = [NSUserDefaults mm_readBool:kShowAppleDictionaryLinkKey defaultValue:YES];
    self.hideMenuBarIcon = [NSUserDefaults mm_readBool:kHideMenuBarIconKey defaultValue:NO];
    self.fixedWindowPosition = [NSUserDefaults mm_readInteger:kShowFixedWindowPositionKey defaultValue:EZShowWindowPositionRight];
    self.mouseSelectTranslateWindowType = [NSUserDefaults mm_readInteger:kMouseSelectTranslateWindowTypeKey defaultValue:EZWindowTypeMini];
    self.shortcutSelectTranslateWindowType = [NSUserDefaults mm_readInteger:kShortcutSelectTranslateWindowTypeKey defaultValue:EZWindowTypeFixed];
    self.adjustPopButtomOrigin = [NSUserDefaults mm_readBool:kAdjustPopButtomOriginKey defaultValue:NO];
    self.allowCrashLog = [NSUserDefaults mm_readBool:kAllowCrashLogKey defaultValue:YES];
    self.allowAnalytics = [NSUserDefaults mm_readBool:kAllowAnalyticsKey defaultValue:YES];
    self.clearInput = [NSUserDefaults mm_readBool:kClearInputKey defaultValue:NO];
    
    self.fontSizes = @[@(1), @(1.1), @(1.2), @(1.3), @(1.4)];
    [[NSUserDefaults standardUserDefaults]registerDefaults:@{kTranslationControllerFontKey: @(0)}];
    
    _fontSizeIndex = [[NSUserDefaults standardUserDefaults]integerForKey:kTranslationControllerFontKey];
    
    self.appearance = [NSUserDefaults mm_readInteger:kApperanceKey defaultValue:AppearenceTypeFollowSystem];
}

#pragma mark - getter

- (BOOL)launchAtStartup {
    BOOL launchAtStartup = [[NSUserDefaults mm_read:kLaunchAtStartupKey] boolValue];
    return launchAtStartup;
}

- (BOOL)automaticallyChecksForUpdates {
    return self.updater.automaticallyChecksForUpdates;
}

- (SPUUpdater *)updater {
    return self.appDelegate.updaterController.updater;
}

#pragma mark - setter

- (void)setFirstLanguage:(EZLanguage)firstLanguage {
    _firstLanguage = firstLanguage;
    
    [NSUserDefaults mm_write:firstLanguage forKey:kFirstLanguageKey];
    
    if (firstLanguage) {
        [self logSettings:@{@"first_language" : firstLanguage}];
    }
}

- (void)setSecondLanguage:(EZLanguage)secondLanguage {
    _secondLanguage = secondLanguage;
    
    [NSUserDefaults mm_write:secondLanguage forKey:kSecondLanguageKey];
    
    if (secondLanguage) {
        [self logSettings:@{@"second_language" : secondLanguage}];
    }
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
    
    [self logSettings:@{@"auto_select_sext" : @(autoSelectText)}];
}

- (void)setForceAutoGetSelectedText:(BOOL)forceGetSelectedText {
    _forceAutoGetSelectedText = forceGetSelectedText;
    
    [NSUserDefaults mm_write:@(forceGetSelectedText) forKey:kForceAutoGetSelectedText];
    
    [self logSettings:@{@"force_get_selected_text" : @(forceGetSelectedText)}];
}

- (void)setDisableEmptyCopyBeep:(BOOL)disableEmptyCopyBeep {
    _disableEmptyCopyBeep = disableEmptyCopyBeep;
    
    [NSUserDefaults mm_write:@(disableEmptyCopyBeep) forKey:kDisableEmptyCopyBeepKey];
    
    [self logSettings:@{@"disableEmptyCopyBeep" : @(disableEmptyCopyBeep)}];
}

- (void)setClickQuery:(BOOL)clickQuery {
    _clickQuery = clickQuery;
    
    [NSUserDefaults mm_write:@(clickQuery) forKey:kClickQueryKey];
    
    [EZWindowManager.shared updatePopButtonQueryAction];
    
    [self logSettings:@{@"click_query" : @(clickQuery)}];
}

- (void)setLaunchAtStartup:(BOOL)launchAtStartup {
    BOOL oldLaunchAtStartup = self.launchAtStartup;
    
    [NSUserDefaults mm_write:@(launchAtStartup) forKey:kLaunchAtStartupKey];
    
    // Avoid redundant calls, run AppleScript will ask for permission, trigger notification.
    if (launchAtStartup != oldLaunchAtStartup) {
        [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
    }
    
    [self logSettings:@{@"launch_at_startup" : @(launchAtStartup)}];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecksForUpdates {    
    self.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates;
    
    [self logSettings:@{@"automatically_checks_for_updates" : @(automaticallyChecksForUpdates)}];
}

- (void)setHideMainWindow:(BOOL)hideMainWindow {
    _hideMainWindow = hideMainWindow;
    
    [NSUserDefaults mm_write:@(hideMainWindow) forKey:kHideMainWindowKey];
    
    EZWindowManager *windowManager = EZWindowManager.shared;
    [windowManager updatePopButtonQueryAction];
    if (hideMainWindow) {
        [windowManager closeMainWindowIfNeeded];
    }
    
    [self logSettings:@{@"hide_main_window" : @(hideMainWindow)}];
}

- (void)setAutoQueryOCRText:(BOOL)autoSnipTranslate {
    _autoQueryOCRText = autoSnipTranslate;
    
    [NSUserDefaults mm_write:@(autoSnipTranslate) forKey:kAutoQueryOCTTextKey];
    
    [self logSettings:@{@"auto_query_ocr_text" : @(autoSnipTranslate)}];
}

- (void)setAutoQuerySelectedText:(BOOL)autoQuerySelectedText {
    _autoQuerySelectedText = autoQuerySelectedText;
    
    [NSUserDefaults mm_write:@(autoQuerySelectedText) forKey:kAutoQuerySelectedTextKey];
    
    [self logSettings:@{@"auto_query_selected_text" : @(autoQuerySelectedText)}];
}

- (void)setAutoQueryPastedText:(BOOL)autoQueryPastedText {
    _autoQueryPastedText = autoQueryPastedText;
    
    [NSUserDefaults mm_write:@(autoQueryPastedText) forKey:kAutoQueryPastedTextKey];
    
    [self logSettings:@{@"auto_query_pasted_text" : @(autoQueryPastedText)}];
}

- (void)setAutoCopyFirstTranslatedText:(BOOL)autoCopyFirstTranslatedText {
    _autoCopyFirstTranslatedText = autoCopyFirstTranslatedText;
    
    [NSUserDefaults mm_write:@(autoCopyFirstTranslatedText) forKey:kAutoCopyFirstTranslatedTextKey];
    
    [self logSettings:@{@"auto_copy_first_translated_text" : @(autoCopyFirstTranslatedText)}];
}

- (void)setAutoPlayAudio:(BOOL)autoPlayAudio {
    _autoPlayAudio = autoPlayAudio;
    
    [NSUserDefaults mm_write:@(autoPlayAudio) forKey:kAutoPlayAudioKey];
    
    [self logSettings:@{@"auto_play_word_audio" : @(autoPlayAudio)}];
}

- (void)setAutoCopySelectedText:(BOOL)autoCopySelectedText {
    _autoCopySelectedText = autoCopySelectedText;
    
    [NSUserDefaults mm_write:@(autoCopySelectedText) forKey:kAutoCopySelectedTextKey];
    
    [self logSettings:@{@"auto_copy_selected_text" : @(autoCopySelectedText)}];
}

- (void)setAutoCopyOCRText:(BOOL)autoCopyOCRText {
    _autoCopyOCRText = autoCopyOCRText;
    
    [NSUserDefaults mm_write:@(autoCopyOCRText) forKey:kAutoCopyOCRTextKey];
    
    [self logSettings:@{@"auto_copy_ocr_text" : @(autoCopyOCRText)}];
}

- (void)setLanguageDetectOptimize:(EZLanguageDetectOptimize)languageDetectOptimizeType {
    _languageDetectOptimize = languageDetectOptimizeType;
    
    [NSUserDefaults mm_write:@(languageDetectOptimizeType) forKey:kLanguageDetectOptimizeTypeKey];
    
    [self logSettings:@{@"detect_optimize" : @(languageDetectOptimizeType)}];
}

- (void)setDefaultTTSServiceType:(EZServiceType)defaultTTSServiceType {
    _defaultTTSServiceType = defaultTTSServiceType;
    [NSUserDefaults mm_write:defaultTTSServiceType forKey:kDefaultTTSServiceTypeKey];
    
    [self logSettings:@{@"tts" : defaultTTSServiceType}];
}

- (void)setShowGoogleQuickLink:(BOOL)showGoogleLink {
    _showGoogleQuickLink = showGoogleLink;
    
    [NSUserDefaults mm_write:@(showGoogleLink) forKey:kShowGoogleLinkKey];
    [self postUpdateQuickLinkButtonNotification];
    
    EZMenuItemManager.shared.googleItem.hidden = !showGoogleLink;
    
    [self logSettings:@{@"show_google_link" : @(showGoogleLink)}];
}

- (void)setShowEudicQuickLink:(BOOL)showEudicLink {
    _showEudicQuickLink = showEudicLink;
    
    [NSUserDefaults mm_write:@(showEudicLink) forKey:kShowEudicLinkKey];
    [self postUpdateQuickLinkButtonNotification];
    
    EZMenuItemManager.shared.eudicItem.hidden = !showEudicLink;
    
    [self logSettings:@{@"show_eudic_link" : @(showEudicLink)}];
}

- (void)setShowAppleDictionaryQuickLink:(BOOL)showAppleDictionaryQuickLink {
    _showAppleDictionaryQuickLink = showAppleDictionaryQuickLink;
    
    [NSUserDefaults mm_write:@(showAppleDictionaryQuickLink) forKey:kShowAppleDictionaryLinkKey];
    [self postUpdateQuickLinkButtonNotification];
    
    EZMenuItemManager.shared.appleDictionaryItem.hidden = !showAppleDictionaryQuickLink;
    
    [self logSettings:@{@"show_apple_dictionary_link" : @(showAppleDictionaryQuickLink)}];
}


- (void)setHideMenuBarIcon:(BOOL)hideMenuBarIcon {
    _hideMenuBarIcon = hideMenuBarIcon;
    
    [NSUserDefaults mm_write:@(hideMenuBarIcon) forKey:kHideMenuBarIconKey];
    
    if (!EasydictNewAppManager.shared.enable) {
        [self hideMenuBarIcon:hideMenuBarIcon];
    }
    
    [self logSettings:@{@"hide_menu_bar_icon" : @(hideMenuBarIcon)}];
}

- (void)setEnableBetaNewApp:(BOOL)enableBetaNewApp {
    _enableBetaNewApp = enableBetaNewApp;
    [NSUserDefaults mm_write:@(enableBetaNewApp) forKey:kEnableBetaNewAppKey];
    [self logSettings:@{@"enable_beta_new_app" : @(enableBetaNewApp)}];
}

- (void)setFixedWindowPosition:(EZShowWindowPosition)showFixedWindowPosition {
    _fixedWindowPosition = showFixedWindowPosition;
    
    [NSUserDefaults mm_write:@(showFixedWindowPosition) forKey:kShowFixedWindowPositionKey];
    
    [self logSettings:@{@"show_fixed_window_position" : @(showFixedWindowPosition)}];
}

- (void)setMouseSelectTranslateWindowType:(EZWindowType)mouseSelectTranslateWindowType {
    _mouseSelectTranslateWindowType = mouseSelectTranslateWindowType;
    
    [NSUserDefaults mm_write:@(mouseSelectTranslateWindowType) forKey:(kMouseSelectTranslateWindowTypeKey)];
    
    [self logSettings:@{@"show_mouse_window_type" : @(mouseSelectTranslateWindowType)}];
}

- (void)setShortcutSelectTranslateWindowType:(EZWindowType)shortcutSelectTranslateWindowType {
    _shortcutSelectTranslateWindowType = shortcutSelectTranslateWindowType;
    
    [NSUserDefaults mm_write:@(shortcutSelectTranslateWindowType) forKey:(kShortcutSelectTranslateWindowTypeKey)];
    
    [self logSettings:@{@"show_shortcut_window_type" : @(shortcutSelectTranslateWindowType)}];
}

- (void)setAdjustPopButtomOrigin:(BOOL)adjustPopButtomOrigin {
    _adjustPopButtomOrigin = adjustPopButtomOrigin;
    
    [NSUserDefaults mm_write:@(adjustPopButtomOrigin) forKey:kAdjustPopButtomOriginKey];
    
    [self logSettings:@{@"adjust_pop_buttom_origin" : @(adjustPopButtomOrigin)}];
}

- (void)setAllowCrashLog:(BOOL)allowCrashLog {
    _allowCrashLog = allowCrashLog;
    
    [NSUserDefaults mm_write:@(allowCrashLog) forKey:kAllowCrashLogKey];
    
    [self logSettings:@{@"allow_crash_log" : @(allowCrashLog)}];
    
    [EZLog setCrashEnabled:allowCrashLog];
}

- (void)setAllowAnalytics:(BOOL)allowAnalytics {
    _allowAnalytics = allowAnalytics;
    
    [NSUserDefaults mm_write:@(allowAnalytics) forKey:kAllowAnalyticsKey];
    
    [self logSettings:@{@"allow_analytics" : @(allowAnalytics)}];
}

- (void)setClearInput:(BOOL)clearInput {
    _clearInput = clearInput;
    
    [NSUserDefaults mm_write:@(clearInput) forKey:kClearInputKey];
    
    [self logSettings:@{@"clear_input" : @(clearInput)}];
}

- (void)setFontSizeIndex:(NSInteger)fontSizeIndex {
    NSInteger targetIndex = MIN(_fontSizes.count-1, MAX(fontSizeIndex, 0));
    
    if (_fontSizeIndex == targetIndex) {
        return;
    }
    
    _fontSizeIndex = targetIndex;
    
    [NSUserDefaults mm_write:@(targetIndex) forKey:kTranslationControllerFontKey];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:ChangeFontSizeView.changeFontSizeNotificationName object:@(targetIndex)];
}

- (CGFloat)fontSizeRatio {
    return _fontSizes[_fontSizeIndex].floatValue;
}

- (void)setAppearance:(EZAppearenceType)appearance {
    _appearance = appearance;
    
    [NSUserDefaults mm_write:@(appearance) forKey:kApperanceKey];
    
    [[DarkModeManager manager] updateDarkMode];
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
        end tell", appName,
                        launchAtStartup ? @"true" : @"false",
                        appBundlePath];
    
    EZScriptExecutor *exeCommand = [[EZScriptExecutor alloc] init];
    [exeCommand runAppleScriptWithTask:script completionHandler:^(NSString *_Nonnull result, NSError *_Nonnull error) {
        if (error) {
            MMLogInfo(@"launchAtStartup error: %@", error);
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
// #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1300
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
// #endif
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
    
    NSDictionary *parameters = @{
        @"enabled" : @(enabled),
        @"window_type" : @(windowType),
    };
    [EZLog logEventWithName:@"intelligent_query_mode" parameters:parameters];
}
- (BOOL)intelligentQueryModeForWindowType:(EZWindowType)windowType {
    NSString *key = [EZConstKey constkey:EZIntelligentQueryModeKey windowType:windowType];
    
    NSString *defaultValue = @"0";
    // Turn on intelligent query mode by default in mini window.
    if (windowType == EZWindowTypeMini) {
        defaultValue = @"1";
    }
    
    NSString *stringValue = [NSUserDefaults mm_readString:key defaultValue:defaultValue];
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
    NSString *stringValue = [NSUserDefaults mm_readString:key defaultValue:@"7"];
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

#pragma mark -

- (void)enableBetaFeaturesIfNeeded {
    if ([self isBeta]) {
    }
}

- (void)logSettings:(NSDictionary *)parameters {
    [EZLog logEventWithName:@"settings" parameters:parameters];
}

@end
