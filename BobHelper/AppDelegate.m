//
//  AppDelegate.m
//  BobHelper
//
//  Created by ripper on 2019/12/10.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    identifier = [identifier stringByReplacingOccurrencesOfString:@"Helper" withString:@""];
    
    __block BOOL alreadyRunning = NO;
    [NSWorkspace.sharedWorkspace.runningApplications enumerateObjectsUsingBlock:^(NSRunningApplication * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bundleIdentifier isEqualToString:identifier]) {
            alreadyRunning = YES;
            *stop = YES;
        }
    }];
    
    if (!alreadyRunning) {
        NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:identifier];
        NSError *error = nil;
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:appURL options:NSWorkspaceLaunchWithoutActivation configuration:@{} error:&error];
        if (error) {
            NSLog(@"Helper 启动 %@ 报错\n%@", identifier, error);
        }
    }
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
