//
//  AppDelegate.m
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "AppDelegate.h"
#import "EZMenuItemManager.h"
#import "EZShortcut.h"
#import "MMCrash.h"
#import "EZWindowManager.h"
#import "EZLanguageManager.h"
#import "EZLog.h"
#import "EZSchemeParser.h"
#import "AppDelegate+EZURLScheme.h"
#import <Sparkle/SPUUpdaterDelegate.h>
#import <Sparkle/SPUStandardUserDriverDelegate.h>
#import "Easydict-Swift.h"

@interface AppDelegate () <SPUUpdaterDelegate, SPUStandardUserDriverDelegate>

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    
    // Capturing crash logs must be placed first.
    [MMCrash registerHandler];
    
    [EZLog setupCrashLogService];
    [EZLog logAppInfo];

    if (!EasydictNewAppManager.shared.enable) {
        [EZMenuItemManager.shared setup];
    }
    
    [EZShortcut setup];

    [EZWindowManager.shared showMainWindowIfNedded];
    
    [self registerRouters];
    
    // Change App icon manually.
    //    NSApplication.sharedApplication.applicationIconImage = [NSImage imageNamed:@"white-black-icon"];
}

/// Auto set up app language.
- (void)setupAppLanguage {
    NSString *systemLanguageCode = @"en-CN";
    if ([EZLanguageManager.shared isSystemChineseFirstLanguage]) {
        systemLanguageCode = @"zh-CN";
    }
    
    [self setupAppLanguage:systemLanguageCode];
}

/// Set up user app language, Chinese or English
- (void)setupAppLanguage:(NSString *)languageCode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *kAppleLanguagesKey = @"AppleLanguages";
    NSMutableArray *userLanguages = [[defaults objectForKey:kAppleLanguagesKey] mutableCopy];
    
    // Avoid two identical languages.
    [userLanguages removeObject:languageCode];
    [userLanguages insertObject:languageCode atIndex:0];
    
    [defaults setObject:userLanguages forKey:kAppleLanguagesKey];
}

- (void)restartApplication {
    NSApplication *application = [NSApplication sharedApplication];
    [application terminate:nil];
    
    // Relaunch app.
    NSString *launchPath = @"/usr/bin/open";
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSArray *arguments = @[bundlePath];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    [task launch];
}


#pragma mark - NSApplicationDelegate

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[EZMenuItemManager shared] remove];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    [EZWindowManager.shared closeMainWindowIfNeeded];

    return NO;
}

#pragma mark - SUUpdaterDelegate

- (NSString *)feedURLStringForUpdater:(SPUUpdater *)updater {
    NSString *feedURLString = @"https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml";
#if DEBUG
    feedURLString = @"http://localhost:8000/appcast.xml";
#endif
    return feedURLString;
}

#pragma mark - SPUStandardUserDriverDelegate

- (BOOL)supportsGentleScheduledUpdateReminders {
    return YES;
}

@end
