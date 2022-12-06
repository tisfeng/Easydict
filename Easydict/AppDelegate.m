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
#import "Configuration.h"
#import "EZWindowManager.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    [MMCrash registerHandler];
    [EZStatusItem.shared setup];
    [EZShortcut setup];

    
    // Show main window?
//    EZWindowManager *windowManager = [EZWindowManager shared];
//    [windowManager.mainWindow setFrameOrigin:CGPointMake(120, 600)];
//    [windowManager.mainWindow center];
//    [windowManager.mainWindow makeKeyAndOrderFront:nil];
    
    
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    
    //    NSApplication.sharedApplication.applicationIconImage = [NSImage imageNamed:@"white-black-icon"];
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
