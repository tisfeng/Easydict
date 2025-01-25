//
//  AppDelegate.m
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+EZURLScheme.h"
#import "Easydict-Swift.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");

    [Shortcut setupShortcut];

    [EZWindowManager.shared showMainWindowIfNeeded];
    
    [self registerRouters];
    
    [[DarkModeManager manager] updateDarkMode:Configuration.shared.appearance];
}

#pragma mark - NSApplicationDelegate

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    // Fix https://github.com/tisfeng/Easydict/issues/447
    [EZWindowManager.shared showMainWindowIfNeeded];
    
    return YES;
}

@end
