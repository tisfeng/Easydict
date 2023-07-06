//
//  EZConfiguration.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"
#import "EZLayoutManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZQuickLinkButtonUpdateNotification = @"EZQuickLinkButtonUpdateNotification";

static NSString *const EZIntelligentQueryModeKey = @"IntelligentQueryMode";

typedef NS_ENUM(NSUInteger, EZLanguageDetectOptimize) {
    EZLanguageDetectOptimizeNone = 0,
    EZLanguageDetectOptimizeBaidu = 1,
    EZLanguageDetectOptimizeGoogle = 2,
};

@interface EZConfiguration : NSObject

@property (nonatomic, copy) EZLanguage firstLanguage;
@property (nonatomic, copy) EZLanguage secondLanguage;

@property (nonatomic, copy) EZLanguage from;
@property (nonatomic, copy) EZLanguage to;

@property (nonatomic, assign) BOOL autoSelectText;
@property (nonatomic, assign) BOOL forceAutoGetSelectedText;
@property (nonatomic, assign) BOOL disableEmptyCopyBeep; // Some apps will beep when empty copy.
@property (nonatomic, assign) BOOL clickQuery;
@property (nonatomic, assign) BOOL launchAtStartup;
@property (nonatomic, assign) BOOL automaticallyChecksForUpdates;
@property (nonatomic, assign) BOOL hideMainWindow;
@property (nonatomic, assign) BOOL autoQueryOCRText;
@property (nonatomic, assign) BOOL autoQuerySelectedText;
@property (nonatomic, assign) BOOL autoQueryPastedText;
@property (nonatomic, assign) BOOL autoPlayAudio;
@property (nonatomic, assign) BOOL autoCopySelectedText;
@property (nonatomic, assign) BOOL autoCopyOCRText;
@property (nonatomic, assign) BOOL autoCopyFirstTranslatedText;
@property (nonatomic, assign) EZLanguageDetectOptimize languageDetectOptimize;
@property (nonatomic, assign) BOOL showGoogleQuickLink;
@property (nonatomic, assign) BOOL showEudicQuickLink;
@property (nonatomic, assign) BOOL hideMenuBarIcon;
@property (nonatomic, assign) EZShowWindowPosition fixedWindowPosition;
@property (nonatomic, assign) BOOL adjustPopButtomOrigin;
@property (nonatomic, assign) BOOL allowCrashLog;
@property (nonatomic, assign) BOOL allowAnalytics;
@property (nonatomic, assign) BOOL clearInput;

/// Only use when showing NSOpenPanel to select disabled apps.
@property (nonatomic, assign) BOOL disabledAutoSelect;


+ (instancetype)shared;
+ (void)destroySharedInstance;

- (CGRect)windowFrameWithType:(EZWindowType)windowType;
- (void)setWindowFrame:(CGRect)frame windowType:(EZWindowType)windowType;


#pragma mark - Intelligent Query Mode
- (void)setIntelligentQueryMode:(BOOL)enabled windowType:(EZWindowType)windowType;
- (BOOL)intelligentQueryModeForWindowType:(EZWindowType)windowType;

#pragma mark - Query Text Type of Service
- (void)setQueryTextType:(EZQueryTextType)queryTextType serviceType:(EZServiceType)serviceType;
- (EZQueryTextType)queryTextTypeForServiceType:(EZServiceType)serviceType;

#pragma mark - Intelligent Query Text Type of Service
- (void)setIntelligentQueryTextType:(EZQueryTextType)queryTextType serviceType:(EZServiceType)serviceType;
- (EZQueryTextType)intelligentQueryTextTypeForServiceType:(EZServiceType)serviceType;


#pragma mark - Beta
@property (nonatomic, assign, readonly, getter=isBeta) BOOL beta;

#pragma mark - Default TTS
@property (nonatomic, copy, readonly) EZServiceType defaultTTSServiceType;

- (void)enableBetaFeaturesIfNeeded;

@end

NS_ASSUME_NONNULL_END
