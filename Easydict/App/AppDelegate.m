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
#import "EZConfiguration.h"
#import "EZLog.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    
    [self setupAppLanguage];
    
    [MMCrash registerHandler];
    [EZLog setupCrashLogService];

    [EZMenuItemManager.shared setup];
    [EZShortcut setup];
    
    [[EZWindowManager shared] showOrHideDockAppAndMainWindow];
    
    // Change App icon manually.
    //    NSApplication.sharedApplication.applicationIconImage = [NSImage imageNamed:@"white-black-icon"];
}


/// Auto set up app language.
- (void)setupAppLanguage {
    NSString *systemLanguageCode = @"en-CN";
    if ([EZLanguageManager isChineseFirstLanguage]) {
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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [EZWindowManager.shared showMainWindow:YES];
    
    [EZLog logWindowAppear:EZWindowTypeMain];
    
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    // Hide dock app, not exit.
    //    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    
    return NO;
}

@end
