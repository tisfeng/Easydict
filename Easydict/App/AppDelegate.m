//
//  AppDelegate.m
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+EZURLScheme.h"


@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");

    [ShortcutManager.shared setupShortcut];

    [EZWindowManager.shared showMainWindowIfNeeded];
    
    [self registerRouters];
    
    [DarkModeManager.shared updateDarkMode:MyConfiguration.shared.appearance];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(vocabularyNotebookWriteFailed:)
                                                 name:NSNotification.vocabularyNotebookWriteFailed
                                               object:nil];
}

- (void)vocabularyNotebookWriteFailed:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleWarning;
        alert.messageText = NSLocalizedString(@"vocabulary_notebook.write_failed_message", nil);
        alert.informativeText = notification.userInfo[UserInfoKey.vocabularyNotebookDirectory];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    });
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
