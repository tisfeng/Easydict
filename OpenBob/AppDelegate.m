//
//  AppDelegate.m
//  Bob
//
//  Created by ripper on 2019/11/20.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "AppDelegate.h"
#import "EZStatusItem.h"
#import "Shortcut.h"
#import "MMCrash.h"
#import "Configuration.h"
#import "EZMainWindow.h"
#import "EZMiniWindowController.h"
#import "EZSelectTextPopWindow.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    [MMCrash registerHandler];
    [EZStatusItem.shared setup];
    [Shortcut setup];
        
    EZMiniWindowController *miniWindowController = [EZMiniWindowController shared];
    [miniWindowController.window center];
    [miniWindowController.window makeKeyAndOrderFront:nil];
    
    
//    EZSelectTextPopWindow *popWindow = [EZSelectTextPopWindow shared];
//    [popWindow center];
//    [popWindow makeKeyAndOrderFront:nil];
        
//    NSApplication.sharedApplication.applicationIconImage = [NSImage imageNamed:@"white-black-icon"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [EZStatusItem.shared remove];
}

@end
