//
//  AppDelegate.m
//  Bob
//
//  Created by ripper on 2019/11/20.
//  Copyright © 2019 ripperhe. All rights reserved.
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


///
- (void)setupAppLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *AppleLanguagesKey = @"AppleLanguages";
    NSMutableArray *userLanguages = [[defaults objectForKey:AppleLanguagesKey] mutableCopy];
    
    NSString *systemLanguageCode = @"en-CN";
    if ([EZLanguageManager isChineseFirstLanguage]) {
        systemLanguageCode = @"zh-CN";
    }
    // Avoid two identical languages.
    [userLanguages removeObject:systemLanguageCode];
    [userLanguages insertObject:systemLanguageCode atIndex:0];
    
    
    // "en-CN", "zh-Hans", "zh-Hans-CN"
    [defaults setObject:userLanguages forKey:AppleLanguagesKey];
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
