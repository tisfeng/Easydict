//
//  AppDelegate.m
//  Bob
//
//  Created by ripper on 2019/11/20.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "AppDelegate.h"
#import "StatusItem.h"
#import "Shortcut.h"
#import "MMCrash.h"
#import "TranslateWindowController.h"
#import "TranslateViewController.h"
#import "Configuration.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    MMLogInfo(@"程序启动");
    [MMCrash registerHandler];
    [StatusItem.shared setup];
    [Shortcut setup];


    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskClosable;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, 300, 400) styleMask:style backing:NSBackingStoreBuffered defer:YES];
    TranslateViewController *translateVC = [[TranslateViewController alloc] init];
    window.contentViewController = translateVC;
    [window center];
    [window makeKeyAndOrderFront:nil];

    Configuration.shared.isFold = NO;
    [translateVC updateFoldState:NO];
    [translateVC resetWithState:@"↩︎ 翻译\n⇧ + ↩︎ 换行\n⌘ + R 重试\n⌘ + W 关闭"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [StatusItem.shared remove];
}

@end
