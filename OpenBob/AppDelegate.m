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
#import "EZWindowManager.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    [MMCrash registerHandler];
    [EZStatusItem.shared setup];
    [Shortcut setup];
        
    EZWindowManager *windowManager = [EZWindowManager shared];
    [windowManager.mainWindow setFrameOrigin:CGPointZero];
    [windowManager.mainWindow makeKeyAndOrderFront:nil];
        
//    NSApplication.sharedApplication.applicationIconImage = [NSImage imageNamed:@"white-black-icon"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [EZStatusItem.shared remove];
}

@end
