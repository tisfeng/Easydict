//
//  AppDelegate.m
//  Bob
//
//  Created by ripper on 2019/11/20.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "AppDelegate.h"
#import "EZStatusItem.h"
#import "EZShortcut.h"
#import "MMCrash.h"
#import "EZWindowManager.h"
#import "EZLanguageManager.h"
#import "EZConfiguration.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    [MMCrash registerHandler];
    [EZStatusItem.shared setup];
    [EZShortcut setup];
    
    NSApplicationActivationPolicy activationPolicy = NSApplicationActivationPolicyAccessory;
    if (!EZConfiguration.shared.hideMainWindow) {
        activationPolicy = NSApplicationActivationPolicyRegular;

        EZWindowManager *windowManager = [EZWindowManager shared];
        [windowManager.mainWindow setFrameOrigin:CGPointMake(120, 600)];
        [windowManager.mainWindow center];
        [windowManager.mainWindow makeKeyAndOrderFront:nil];
    }
    [NSApp setActivationPolicy:activationPolicy];

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

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[EZStatusItem shared] remove];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [EZWindowManager.shared.mainWindow makeKeyAndOrderFront:nil];
    
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    // Hide dock app, not exit.
    //    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    
    return NO;
}

@end
