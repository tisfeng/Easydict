//
//  AppDelegate.m
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "AppDelegate.h"
#import "EZShortcut.h"
#import "MMCrash.h"
#import "AppDelegate+EZURLScheme.h"
#import "EZAboutViewController.h"

@interface AppDelegate ()

@property (strong) NSWindowController *aboutWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    
    // Capturing crash logs must be placed first.
    [MMCrash registerHandler];
    
    [EZLog setupCrashLogService];
    [EZLog logAppInfo];

    if (!Configuration.shared.enableBetaNewApp) {
        [EZMenuItemManager.shared setup];
        [EZShortcut setup];
    } else {
        [Shortcut setupShortcut];
    }

    [EZWindowManager.shared showMainWindowIfNeeded];
    
    [self registerRouters];
    
    [[DarkModeManager manager] updateDarkMode:Configuration.shared.appearance];
    // Change App icon manually.
    //    NSApplication.sharedApplication.applicationIconImage = [NSImage imageNamed:@"white-black-icon"];
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

- (void)showAboutPanel {
    if (self.aboutWindowController == nil) {
        NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;

        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300)
                                                       styleMask:styleMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];

        // Hide title text && set transparent title bar
        [window setTitleVisibility:NSWindowTitleHidden];
        [window setTitlebarAppearsTransparent:YES];
        
        AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
        [window setContentViewController:aboutViewController];
        
        self.aboutWindowController = [[NSWindowController alloc] initWithWindow:window];
    }
    
    [self.aboutWindowController.window center];
    [self.aboutWindowController showWindow:nil];
}

#pragma mark - NSApplicationDelegate

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[EZMenuItemManager shared] remove];
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
